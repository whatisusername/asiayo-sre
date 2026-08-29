package main

import (
	"bytes"
	"os"
	"path/filepath"
	"testing"
)

func TestMostFrequentWord(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		wantWord  string
		wantCount int
	}{
		{
			name:      "counts words in one line",
			input:     "apple banana apple orange apple banana",
			wantWord:  "apple",
			wantCount: 3,
		},
		{
			name:      "ignores letter case",
			input:     "Go go GO gO Rust rust",
			wantWord:  "go",
			wantCount: 4,
		},
		{
			name:      "counts across multiple lines",
			input:     "cat dog\ncat bird\ndog cat",
			wantWord:  "cat",
			wantCount: 3,
		},
		{
			name:      "ignores punctuation around words",
			input:     "Hello, world! HELLO. hello? World.",
			wantWord:  "hello",
			wantCount: 3,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gotWord, gotCount := mostFrequentWord(tt.input)

			if gotWord != tt.wantWord || gotCount != tt.wantCount {
				t.Fatalf(
					"mostFrequentWord(%q) = (%q, %d), want (%q, %d)",
					tt.input,
					gotWord,
					gotCount,
					tt.wantWord,
					tt.wantCount,
				)
			}
		})
	}
}

func TestRun(t *testing.T) {
	tests := []struct {
		name        string
		input       string
		wantOutput  string
		wantErr     bool
		missingFile bool
	}{
		{
			name:       "reads a file and writes the required format",
			input:      "Twinkle, twinkle, little star,\nHow I wonder what you are.\nTWINKLE!",
			wantOutput: "3 twinkle\n",
		},
		{
			name:        "returns an error when the input file does not exist",
			wantErr:     true,
			missingFile: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			filePath := filepath.Join(t.TempDir(), "words.txt")
			if !tt.missingFile {
				if err := os.WriteFile(filePath, []byte(tt.input), 0o600); err != nil {
					t.Fatalf("write test input: %v", err)
				}
			}

			var output bytes.Buffer
			err := run(filePath, &output)

			if tt.wantErr {
				if err == nil {
					t.Fatal("run() error = nil, want an error")
				}
				return
			}
			if err != nil {
				t.Fatalf("run() returned an unexpected error: %v", err)
			}
			if got := output.String(); got != tt.wantOutput {
				t.Fatalf("run() output = %q, want %q", got, tt.wantOutput)
			}
		})
	}
}
