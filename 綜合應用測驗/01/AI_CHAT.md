# AI 對話紀錄

- AI 工具：Codex
- 模型：GPT-5.6 Sol
- Reasoning level：Medium
- 使用目的：協助進行 TDD 開發

以下是按照題目重新整理後提供給 AI，並未提供原始題目全文。

---

## Prompt 1

> 使用 Go 語言撰寫一個可執行腳本
>
> 功能：
>   - 讀取 `words.txt`
>   - 找出檔案中重複次數最多的英文單字
>   - 單字比對忽略大小寫
>   - 輸入內容可能包含多行文字
>   - 輸出格式為`<重複次數> <單字>`
>
> 工作目錄：`綜合應用測驗\01`
>
> 專案結構：
>   - 程式檔案：main.go
>   - 測試檔案：main_test.go
>   - Package：main
>
> 開發要求：
>   - 只使用 Go 標準函式庫
>   - 以 TDD 的方式開發
>   - 單元測試使用 Go 內建的 testing package，並採用 table-driven tests 搭配 t.Run()
>   - 第一階段先分析需求並撰寫測試，不實作正式程式碼

```txt
第一階段 TDD「Red」已完成。

新增 綜合應用測驗/01/main_test.go，包含：

- Table-driven tests 與 t.Run()
- 單行文字統計
- 忽略英文大小寫
- 跨多行統計
- 忽略單字周圍標點
- 讀取 words.txt 類型的檔案
- 驗證輸出格式：<次數> <小寫單字>\n
- 檔案不存在時回傳錯誤

測試預定的程式介面：

func mostFrequentWord(input string) (string, int)
func run(filePath string, output io.Writer) error

目前 go test ./... 如預期失敗：

undefined: mostFrequentWord
undefined: run

尚未建立 main.go 或實作正式程式碼，符合第一階段要求。並列最高次數的處理方式因需求未定義，目前測試刻意未鎖定該行為。
```

## Prompt 2

> 目前 test case 符合需求，可以開始進行 TDD 的實作階段
>
> 工作目錄：`綜合應用測驗\01`
>
> 依現有 `main_test.go` 進行以下任務：
>
> - 在 `main.go` 實作，並讓所有測試通過
> - 不修改目前的 test case，除非發現測試本身有錯誤
> - 只使用 Go 標準函式庫
> - `main()` 預設讀取該工作目錄下的 `words.txt`
> - 執行所有測試並通過
> - 最後實際執行程式，確認輸出格式為 `<重複次數> <單字>`

```txt
已完成 綜合應用測驗/01/main.go：

  - 僅使用 Go 標準函式庫
  - 支援忽略大小寫與標點符號
  - main() 預設讀取工作目錄的 words.txt
  - 未修改任何 test case
  - go test ./... 全數通過
  - 實際執行輸出：

  4 twinkle

  格式符合 <重複次數> <單字>。
```
