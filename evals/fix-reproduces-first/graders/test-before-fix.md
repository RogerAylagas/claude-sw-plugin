---
type: tool_order
before:
  tool: Edit
  input_match: 'test_stats\.py'
after:
  tool: Edit
  input_match: '"file_path"\s*:\s*"[^"]*src[/\\]+stats\.py"'
weight: 2
---
