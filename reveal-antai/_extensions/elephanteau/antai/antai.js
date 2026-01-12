window.RevealAntAI = window.RevealAntAI || (() => {
  console.log("Ant-AI: Extension script loaded.");

  function getPluginConfig() {
    // Reveal might not be fully ready, but the config should be accessible if Reveal context exists
    if (typeof Reveal !== 'undefined' && Reveal.getConfig) {
      return Reveal.getConfig().antai || {};
    }
    return {};
  }

  function createWidget() {
    console.log("Ant-AI: Creating widget...");
    if (document.getElementById('antai-chat-widget')) {
      console.log("Ant-AI: Widget already exists.");
      return;
    }

    const config = getPluginConfig();
    const serverUrl = config.serverUrl || 'http://localhost:3000/v1/chat/completions';
    const apiKey = config.apiKey || 'dummy-key';
    console.log("Ant-AI: Configured serverUrl:", serverUrl);

    const instructions = config.instructions || config.systemInstruction;
    let conversationHistory = [];
    if (instructions) {
      conversationHistory.push({ role: 'system', content: instructions });
    }

    const wrapper = document.createElement('div');
    wrapper.id = 'antai-chat-widget';

    const container = document.createElement('div');
    container.id = 'antai-chat-container';
    container.innerHTML = `
      <div id="antai-chat-header">
        <span>Ant-AI Chat</span>
        <button id="antai-close-btn">&times;</button>
      </div>
      <div id="antai-chat-messages"></div>
      <div id="antai-chat-input-area">
        <input type="text" id="antai-chat-input" placeholder="Ask AI..." />
        <button id="antai-chat-send">➤</button>
      </div>
    `;

    const toggleBtn = document.createElement('button');
    toggleBtn.id = 'antai-chat-toggle';
    toggleBtn.innerHTML = '<img src="_extensions/elephanteau/antai/antai_escp.png" alt="Ant-AI" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;">';
    toggleBtn.title = "Open AI Chat";
    toggleBtn.onclick = () => {
      container.style.display = container.style.display === 'flex' ? 'none' : 'flex';
      if (container.style.display === 'flex') {
        document.getElementById('antai-chat-input').focus();
      }
    };

    wrapper.appendChild(container);
    wrapper.appendChild(toggleBtn);
    document.body.appendChild(wrapper);
    console.log("Ant-AI: Widget injected into DOM.");

    // Event listeners
    document.getElementById('antai-close-btn').addEventListener('click', () => {
      container.style.display = 'none';
    });

    const input = document.getElementById('antai-chat-input');
    const sendBtn = document.getElementById('antai-chat-send');

    const sendMessage = async () => {
      const text = input.value.trim();
      if (!text) return;

      conversationHistory.push({ role: 'user', content: text });
      addMessage(text, 'user');
      input.value = '';

      try {
        console.log("Ant-AI: Sending request to", serverUrl);
        const response = await fetch(serverUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`
          },
          body: JSON.stringify({
            model: config.model || 'gpt-3.5-turbo',
            messages: conversationHistory
          })
        });

        const data = await response.json();
        const aiText = data.choices && data.choices[0] && data.choices[0].message ? data.choices[0].message.content : 'Error: Invalid response format';

        conversationHistory.push({ role: 'assistant', content: aiText });
        addMessage(aiText, 'ai', true);

      } catch (error) {
        console.error('Ant-AI Error:', error);
        addMessage('Error connecting to AI server. Check console for details.', 'ai');
      }
    };

    sendBtn.addEventListener('click', sendMessage);
    input.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendMessage();
    });
  }

  function addMessage(text, sender, isMarkdown = false) {
    const messagesDiv = document.getElementById('antai-chat-messages');
    if (!messagesDiv) return;
    const msgDiv = document.createElement('div');
    msgDiv.classList.add('antai-message', sender === 'user' ? 'antai-user' : 'antai-ai');

    if (isMarkdown && typeof marked !== 'undefined') {
      msgDiv.innerHTML = marked.parse(text);
    } else {
      msgDiv.textContent = text;
    }

    messagesDiv.appendChild(msgDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
  }

  function init() {
    if (typeof Reveal === 'undefined') {
      console.log("Ant-AI: Reveal global not found, checking again in 100ms...");
      setTimeout(init, 100);
      return;
    }

    if (Reveal.isReady()) {
      createWidget();
    } else {
      Reveal.addEventListener('ready', createWidget);
    }
  }

  // Start initialization
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
