package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path"
	"sort"
	"strings"
	"sync"
	"time"
)

const (
	hfAPIBase      = "https://huggingface.co/api/models"
	defaultMaxSize = 120 // GB - Strix Halo: 128GB UMA - 8GB system
	defaultLimit   = 30
	defaultSort    = "likes7d"
	maxConcurrent  = 10
)

// Colors
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[0;31m"
	colorGreen  = "\033[0;32m"
	colorYellow = "\033[1;33m"
	colorCyan   = "\033[0;36m"
	colorBold   = "\033[1m"
)

// Model represents a HuggingFace model from the API
type Model struct {
	ID        string `json:"id"`
	Author    string `json:"author"`
	Downloads int64  `json:"downloads"`
	Likes     int    `json:"likes"`
	CreatedAt string `json:"createdAt"`
	GGUF      *struct {
		Total        int64  `json:"total"`
		Architecture string `json:"architecture"`
		ContextLen   int    `json:"context_length"`
	} `json:"gguf"`
	Tags        []string `json:"tags"`
	PipelineTag string   `json:"pipeline_tag"`
}

// TreeEntry represents a file or directory in the model tree
type TreeEntry struct {
	Type string `json:"type"`
	Path string `json:"path"`
	Size int64  `json:"size"`
}

// GGUFFile represents a GGUF file with its size
type GGUFFile struct {
	Name string
	Size int64
}

// ModelWithFiles combines model info with actual file sizes
type ModelWithFiles struct {
	Model
	Files      []GGUFFile
	SmallestFit *GGUFFile
	LargestFit  *GGUFFile
	Error      error
}

var client = &http.Client{
	Timeout: 30 * time.Second,
}

func main() {
	var (
		maxSizeGB   = flag.Int("max-size", defaultMaxSize, "Maximum model size in GB")
		limit       = flag.Int("limit", defaultLimit, "Number of models to fetch")
		sortBy      = flag.String("sort", defaultSort, "Sort by: likes7d (trending), downloads, likes")
		search      = flag.String("search", "", "Search for models by name")
		author      = flag.String("author", "", "Filter by author")
		details     = flag.String("details", "", "Show detailed info for a specific model")
		showHelp    = flag.Bool("help", false, "Show help")
	)
	flag.Parse()

	if *showHelp {
		printUsage()
		return
	}

	maxSizeBytes := int64(*maxSizeGB) * 1024 * 1024 * 1024

	if *details != "" {
		showModelDetails(*details, maxSizeBytes)
		return
	}

	models, err := fetchModels(*sortBy, *limit, *search, *author)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%sError fetching models: %v%s\n", colorRed, err, colorReset)
		os.Exit(1)
	}

	// Fetch file sizes concurrently
	modelsWithFiles := fetchAllModelFiles(models, maxSizeBytes)

	// Display results
	displayModelList(modelsWithFiles, *maxSizeGB, maxSizeBytes)
}

func printUsage() {
	fmt.Printf(`%shf-model-scout%s - Discover GGUF models for your hardware

%sUSAGE:%s
    hf-model-scout [OPTIONS]

%sOPTIONS:%s
    -max-size SIZE    Maximum model size in GB (default: %d)
    -limit N          Number of models to fetch (default: %d)
    -sort FIELD       Sort by: likes7d (trending), downloads, likes (default: %s)
    -search QUERY     Search for models by name
    -author AUTHOR    Filter by author (e.g., bartowski, unsloth)
    -details MODEL    Show detailed info for a specific model
    -help             Show this help

%sEXAMPLES:%s
    hf-model-scout
    hf-model-scout -search qwen -limit 20
    hf-model-scout -author bartowski -sort downloads
    hf-model-scout -details bartowski/Llama-3.3-70B-Instruct-GGUF

`, colorBold, colorReset,
		colorBold, colorReset,
		colorBold, colorReset,
		defaultMaxSize, defaultLimit, defaultSort,
		colorBold, colorReset)
}

func fetchModels(sortBy string, limit int, search, author string) ([]Model, error) {
	u, _ := url.Parse(hfAPIBase)
	q := u.Query()
	q.Set("filter", "gguf")
	q.Set("pipeline_tag", "text-generation")
	q.Set("sort", sortBy)
	q.Set("direction", "-1")
	q.Set("limit", fmt.Sprintf("%d", limit))
	if search != "" {
		q.Set("search", search)
	}
	if author != "" {
		q.Set("author", author)
	}
	u.RawQuery = q.Encode()

	resp, err := client.Get(u.String())
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var models []Model
	if err := json.NewDecoder(resp.Body).Decode(&models); err != nil {
		return nil, err
	}
	return models, nil
}

func fetchModelTree(modelID, subpath string) ([]TreeEntry, error) {
	u := fmt.Sprintf("%s/%s/tree/main", hfAPIBase, modelID)
	if subpath != "" {
		u = fmt.Sprintf("%s/%s", u, subpath)
	}

	resp, err := client.Get(u)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var entries []TreeEntry
	if err := json.NewDecoder(resp.Body).Decode(&entries); err != nil {
		return nil, err
	}
	return entries, nil
}

func fetchAllGGUFFiles(modelID string) ([]GGUFFile, error) {
	entries, err := fetchModelTree(modelID, "")
	if err != nil {
		return nil, err
	}

	var files []GGUFFile
	var dirs []string

	for _, e := range entries {
		if e.Type == "file" && strings.HasSuffix(e.Path, ".gguf") {
			files = append(files, GGUFFile{Name: e.Path, Size: e.Size})
		} else if e.Type == "directory" {
			dirs = append(dirs, e.Path)
		}
	}

	// Check directories for split files
	var wg sync.WaitGroup
	var mu sync.Mutex
	sem := make(chan struct{}, 5) // Limit concurrent subdirectory fetches

	for _, dir := range dirs {
		wg.Add(1)
		go func(d string) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()

			subEntries, err := fetchModelTree(modelID, d)
			if err != nil {
				return
			}

			var totalSize int64
			hasGGUF := false
			for _, e := range subEntries {
				if strings.HasSuffix(e.Path, ".gguf") {
					totalSize += e.Size
					hasGGUF = true
				}
			}

			if hasGGUF {
				mu.Lock()
				files = append(files, GGUFFile{
					Name: path.Base(d) + ".gguf",
					Size: totalSize,
				})
				mu.Unlock()
			}
		}(dir)
	}
	wg.Wait()

	// Sort by size
	sort.Slice(files, func(i, j int) bool {
		return files[i].Size < files[j].Size
	})

	return files, nil
}

func fetchAllModelFiles(models []Model, maxSizeBytes int64) []ModelWithFiles {
	results := make([]ModelWithFiles, len(models))
	var wg sync.WaitGroup
	sem := make(chan struct{}, maxConcurrent)

	for i, m := range models {
		wg.Add(1)
		go func(idx int, model Model) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()

			mwf := ModelWithFiles{Model: model}
			files, err := fetchAllGGUFFiles(model.ID)
			if err != nil {
				mwf.Error = err
			} else {
				mwf.Files = files
				// Find smallest and largest that fit
				for i := range files {
					if files[i].Size <= maxSizeBytes {
						if mwf.SmallestFit == nil {
							mwf.SmallestFit = &files[i]
						}
						mwf.LargestFit = &files[i]
					}
				}
			}
			results[idx] = mwf
		}(i, m)
	}
	wg.Wait()

	return results
}

func formatSize(bytes int64) string {
	gb := float64(bytes) / (1024 * 1024 * 1024)
	if gb < 1 {
		return fmt.Sprintf("%.0f MB", gb*1024)
	}
	return fmt.Sprintf("%.1f GB", gb)
}

func formatDownloads(n int64) string {
	if n >= 1000000 {
		return fmt.Sprintf("%.1fM", float64(n)/1000000)
	}
	if n >= 1000 {
		return fmt.Sprintf("%.1fK", float64(n)/1000)
	}
	return fmt.Sprintf("%d", n)
}

func displayModelList(models []ModelWithFiles, maxSizeGB int, maxSizeBytes int64) {
	fmt.Printf("\n%s%sTrending GGUF Models (max %dGB)%s\n", colorBold, colorCyan, maxSizeGB, colorReset)
	fmt.Printf("%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n", colorBold, colorReset)

	fmt.Printf("%s%-45s %10s %6s %12s %12s%s\n", colorBold, "MODEL", "DOWNLOADS", "LIKES", "SMALLEST", "LARGEST", colorReset)
	fmt.Println("─────────────────────────────────────────────────────────────────────────────────────────")

	for _, m := range models {
		displayID := m.ID
		if len(displayID) > 43 {
			displayID = displayID[:40] + "..."
		}

		smallest := "?"
		largest := "?"
		fit := colorYellow + "?" + colorReset

		if m.Error == nil {
			if m.SmallestFit != nil {
				smallest = formatSize(m.SmallestFit.Size)
				largest = formatSize(m.LargestFit.Size)
				fit = colorGreen + "✓" + colorReset
			} else if len(m.Files) > 0 {
				// Has files but none fit
				smallest = formatSize(m.Files[0].Size)
				largest = formatSize(m.Files[len(m.Files)-1].Size)
				fit = colorRed + "✗" + colorReset
			}
		}

		fmt.Printf("%-45s %10s %6d %12s %12s %s\n",
			displayID,
			formatDownloads(m.Downloads),
			m.Likes,
			smallest,
			largest,
			fit,
		)
	}

	fmt.Printf("\nFound %s%d%s models. Use %s-details MODEL_ID%s for full file list.\n",
		colorBold, len(models), colorReset, colorCyan, colorReset)
}

func showModelDetails(modelID string, maxSizeBytes int64) {
	fmt.Printf("\n%s%sFetching details for: %s%s\n\n", colorBold, colorCyan, modelID, colorReset)

	// Fetch model info
	resp, err := client.Get(fmt.Sprintf("%s/%s", hfAPIBase, modelID))
	if err != nil {
		fmt.Fprintf(os.Stderr, "%sError: %v%s\n", colorRed, err, colorReset)
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var model Model
	json.Unmarshal(body, &model)

	fmt.Printf("%sModel:%s     %s\n", colorBold, colorReset, modelID)
	fmt.Printf("%sAuthor:%s    %s\n", colorBold, colorReset, model.Author)
	fmt.Printf("%sDownloads:%s %s\n", colorBold, colorReset, formatDownloads(model.Downloads))
	fmt.Printf("%sLikes:%s     %d\n", colorBold, colorReset, model.Likes)

	if model.GGUF != nil {
		if model.GGUF.Architecture != "" {
			fmt.Printf("%sArch:%s      %s\n", colorBold, colorReset, model.GGUF.Architecture)
		}
		if model.GGUF.ContextLen > 0 {
			fmt.Printf("%sContext:%s   %d tokens\n", colorBold, colorReset, model.GGUF.ContextLen)
		}
	}

	// Fetch files
	files, err := fetchAllGGUFFiles(modelID)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%sError fetching files: %v%s\n", colorRed, err, colorReset)
		return
	}

	fmt.Printf("\n%s%sAvailable GGUF Files:%s\n", colorBold, colorYellow, colorReset)
	fmt.Println("──────────────────────────────────────────────────────────────────────────")
	fmt.Printf("%s%-50s %12s %s%s\n", colorBold, "FILENAME", "SIZE", "FIT", colorReset)
	fmt.Println("──────────────────────────────────────────────────────────────────────────")

	quantQuality := map[string]string{
		"Q8_0":   "Excellent",
		"Q6_K":   "Very Good",
		"Q5_K_M": "Good",
		"Q5_K_S": "Good",
		"Q4_K_M": "Decent",
		"Q4_K_S": "Decent",
		"Q3_K_M": "Fair",
		"Q3_K_L": "Fair",
		"Q3_K_XL": "Fair+",
		"IQ4_XS": "Good",
		"IQ3_M":  "Fair",
	}

	for _, f := range files {
		displayName := f.Name
		if len(displayName) > 48 {
			displayName = displayName[:45] + "..."
		}

		fit := colorGreen + "✓" + colorReset
		if f.Size > maxSizeBytes {
			fit = colorRed + "✗" + colorReset
		}

		quality := ""
		for q, desc := range quantQuality {
			if strings.Contains(f.Name, q) {
				quality = " (" + desc + ")"
				break
			}
		}

		fmt.Printf("%-50s %12s %s%s\n", displayName, formatSize(f.Size), fit, quality)
	}

	fmt.Printf("\n%sDownload URL pattern:%s\n", colorCyan, colorReset)
	fmt.Printf("  https://huggingface.co/%s/resolve/main/FILENAME\n", modelID)
}
