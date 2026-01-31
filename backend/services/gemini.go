package services

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

type GeminiService struct {
	client *genai.Client
	model  *genai.GenerativeModel
}

func NewGeminiService() (*GeminiService, error) {
	ctx := context.Background()
	client, err := genai.NewClient(ctx, option.WithAPIKey(os.Getenv("GEMINI_API_KEY")))
	if err != nil {
		return nil, err
	}

	// Gunakan model yang support, misal gemini-1.5-flash atau gemini-2.0-flash-exp (jika ada)
	// Sesuaikan dengan availability di akunmu
	model := client.GenerativeModel("gemini-2.5-flash") 
	model.SetTemperature(0.7)
	model.ResponseMIMEType = "application/json"

	// System instruction dalam Bahasa Inggris
	model.SystemInstruction = &genai.Content{
		Parts: []genai.Part{
			genai.Text(`You are an AI assistant for a customer support team.
Your task is to analyze customer messages and provide helpful insights.
Always provide responses in professional and empathetic English.`),
		},
	}

	return &GeminiService{
		client: client,
		model:  model,
	}, nil
}

// AnalyzeMessage - Analisis pesan (Input bebas, Output JSON tetap Inggris)
func (s *GeminiService) AnalyzeMessage(content string) (map[string]interface{}, error) {
	prompt := fmt.Sprintf(`Analyze the following customer support message (which might be in Indonesian or English) and return ONLY a JSON object with these exact fields:

{
  "sentiment": "Angry" | "Frustrated" | "Neutral" | "Happy" | "Satisfied",
  "category": "Technical" | "Billing" | "Feature Request" | "General Question" | "Complaint",
  "priority": "High" | "Medium" | "Low",
  "urgency_level": "High" | "Medium" | "Low",
  "sentiment_score": <number between 0-1, where 0=very negative, 1=very positive>
}

Analysis Rules:
- The input text can be in Indonesian or English.
- HOWEVER, the JSON values MUST always be in English (e.g. use "High" not "Tinggi").
- If message contains urgent words (urgent, ASAP, immediately, critical) -> Priority "High"
- If sentiment is "Angry" or "Frustrated" -> Urgency "High"
- If mentions bug, error, cannot login, crash -> Category "Technical"
- If mentions invoice, payment, refund, charged -> Category "Billing"

Customer Message:
"%s"

Return ONLY valid JSON, no markdown formatting, no explanations.`, content)

	resp, err := s.model.GenerateContent(context.Background(), genai.Text(prompt))
	if err != nil {
		return nil, fmt.Errorf("failed to call Gemini API: %v", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("no response from AI")
	}

	jsonStr := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])

	var result map[string]interface{}
	if err := json.Unmarshal([]byte(jsonStr), &result); err != nil {
		return nil, fmt.Errorf("failed to parse AI response: %v", err)
	}

	return result, nil
}

// SummarizeConversation - Summarize conversation in English
func (s *GeminiService) SummarizeConversation(messages []string) (string, error) {
	conversation := ""
	for i, msg := range messages {
		conversation += fmt.Sprintf("Message %d: %s\n", i+1, msg)
	}

	prompt := fmt.Sprintf(`Summarize this customer support conversation in 2-3 clear, concise sentences.
Focus on:
1. The main issue experienced by the customer
2. The current status or situation
3. Action items taken or needed

Conversation:
%s

Summary:`, conversation)

	resp, err := s.model.GenerateContent(context.Background(), genai.Text(prompt))
	if err != nil {
		return "", fmt.Errorf("failed to generate summary: %v", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("no response from AI")
	}

	summary := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])
	return summary, nil
}

// SuggestResponse - Saran balasan mengikuti bahasa customer
func (s *GeminiService) SuggestResponse(messageContent string, sentiment string, category string) (string, error) {
	prompt := fmt.Sprintf(`You are a professional customer support agent.
Draft a helpful response for the following customer message.

Customer Info:
- Sentiment: %s
- Category: %s
- Message: "%s"

Response Guidelines:
1. DETECT the language of the 'Message' above (Indonesian or English).
2. DRAFT the response IN THE SAME LANGUAGE as the customer's message.
3. Start with a polite greeting.
4. Show empathy regarding their issue.
5. Provide a clear solution or next steps.
6. Close with a positive and professional tone.

Special handling for "Angry" or "Frustrated":
- Extra empathy and apologize if applicable.
- Show urgency in resolving the matter.

Draft Response (in customer's language):`, sentiment, category, messageContent)

	resp, err := s.model.GenerateContent(context.Background(), genai.Text(prompt))
	if err != nil {
		return "", fmt.Errorf("failed to suggest response: %v", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("no response from AI")
	}

	response := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])
	return response, nil
}


// GetSentimentTrends - Analyze trends in English
func (s *GeminiService) GetSentimentTrends(messages []map[string]interface{}) (string, error) {
	// Format messages for analysis
	messagesList := ""
	for i, msg := range messages {
		messagesList += fmt.Sprintf("%d. [%s] %s - Sentiment: %s\n",
			i+1,
			msg["created_at"],
			msg["content"],
			msg["sentiment"])
	}

	prompt := fmt.Sprintf(`Analyze the sentiment trends from the following customer support messages.
Provide insights in a short paragraph (3-4 sentences) covering:
1. Dominant sentiment
2. Observed patterns or recurring issues
3. Recommended actions for the support team

Messages Data:
%s

Trend Analysis:`, messagesList)

	resp, err := s.model.GenerateContent(context.Background(), genai.Text(prompt))
	if err != nil {
		return "", fmt.Errorf("failed to analyze trends: %v", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return "", fmt.Errorf("no response from AI")
	}

	analysis := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])
	return analysis, nil
}

func (s *GeminiService) Close() {
	s.client.Close()
}