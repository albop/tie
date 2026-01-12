function Meta(meta)
  local antai = meta.antai
  if antai then
    -- Convert pandoc MetaMap to a Lua table
    local config = {}
    for k, v in pairs(antai) do
      config[k] = pandoc.utils.stringify(v)
    end
    
    local json_config = quarto.json.encode(config)
    local script = "<script>window.RevealAntAIConfig = " .. json_config .. ";</script>"
    quarto.doc.include_text("after-body", script)
  end
end
