class PromptsController < ApplicationController
  def index
  end

  def create
    client = Gemini.new(
      credentials: {
        service: 'vertex-ai-api',
        region: 'us-central1',
        project_id: Rails.application.credentials.google.vertex_ai.project_id
      },
      options: { model: 'gemini-2.5-flash', server_sent_events: true }
    )

    result = client.generate_content({
      contents: { role: 'user', parts: { text: params[:prompt] } }
    })

    @response_text = result.dig("candidates", 0, "content", "parts", 0, "text")

    render :index
  end
end
