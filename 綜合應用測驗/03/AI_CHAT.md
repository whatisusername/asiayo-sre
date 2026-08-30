# AI 對話紀錄

- AI 工具：ChatGPT
- 模型：GPT-5.6 Sol
- 使用目的：協助確認 SQL 排名與資料表關聯的處理方式

---

## Prompt 1

> 有一個資料庫 `student`，其包含 `score` 與 `class` 兩張 table
>
> `score` 包含：
> - `name`
> - `score`
>
> `class` 包含：
> - `name`
> - `class`
>
> 題目需要找出分數排名第二的學生所在班級
>
> 題目沒有提供 PK、FK，也沒有特別指定資料庫類型，可先假設是用 MySQL
> 希望考慮多人同分的情況，請撰寫 SQL

```txt
建議使用 Window Function 的 `DENSE_RANK()` 進行排名。

相較於：

- `ROW_NUMBER()`：即使分數相同，仍會依資料列分配不同順位。
- `RANK()`：同分後會跳過後續順位，例如兩位第一名後下一名會是第三名。
- `DENSE_RANK()`：同分使用相同順位，且後續順位保持連續，較符合「第二高分」的語意。

題目未提供 PK / FK，因此可先假設 `score.name` 與 `class.name` 能關聯同一位學生。

若只需要輸出第二名學生所在的班級，可將排名結果與 `class` table 透過 `name` JOIN，並使用 `DISTINCT` 避免多位第二名學生位於相同班級時重複輸出。

範例：

```sql
SELECT DISTINCT c.class
FROM (
    SELECT
        name,
        DENSE_RANK() OVER (ORDER BY score DESC) AS ranking
    FROM score
) AS ranked
JOIN class AS c
    ON ranked.name = c.name
WHERE ranked.ranking = 2;
```
```
