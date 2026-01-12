#!/bin/bash
# Test if the LLM server is accessible

echo "Testing LLM server at http://127.0.0.1:1234/v1/chat/completions"
echo ""

curl -v -X POST http://127.0.0.1:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{
    "model": "llama-3.2-1b-instruct",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
