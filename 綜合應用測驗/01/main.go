package main

import (
	"fmt"
	"io"
	"os"
	"strings"
	"unicode"
)

func mostFrequentWord(input string) (string, int) {
	words := strings.FieldsFunc(input, func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsNumber(r)
	})

	counts := make(map[string]int, len(words))
	mostFrequent := ""
	mostFrequentCount := 0

	for _, word := range words {
		word = strings.ToLower(word)
		counts[word]++
		if counts[word] > mostFrequentCount {
			mostFrequent = word
			mostFrequentCount = counts[word]
		}
	}

	return mostFrequent, mostFrequentCount
}

func run(filePath string, output io.Writer) error {
	contents, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("read input file: %w", err)
	}

	word, count := mostFrequentWord(string(contents))
	if _, err := fmt.Fprintf(output, "%d %s\n", count, word); err != nil {
		return fmt.Errorf("write output: %w", err)
	}

	return nil
}

func main() {
	if err := run("words.txt", os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
