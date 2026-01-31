package handlers

import (
    "ai-support-backend/models"
    "ai-support-backend/services"
    "strconv"
    "fmt"
    "github.com/gofiber/fiber/v2"
    "gorm.io/gorm"
)

type MessageHandler struct {
    db     *gorm.DB
    gemini *services.GeminiService
}

func NewMessageHandler(db *gorm.DB, gemini *services.GeminiService) *MessageHandler {
    return &MessageHandler{db: db, gemini: gemini}
}

func (h *MessageHandler) CreateMessage(c *fiber.Ctx) error {
    // 1. Parse Request
    type Request struct {
        CustomerName string `json:"customer_name"`
        Content      string `json:"content"`
    }
    req := new(Request)
    if err := c.BodyParser(req); err != nil {
        return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
    }

    // 2. AI Analysis
    analysis, err := h.gemini.AnalyzeMessage(req.Content)
    if err != nil {
        fmt.Println("❌ ERROR GEMINI:", err)
        return c.Status(500).JSON(fiber.Map{"error": "AI analysis failed"})
    }

    // ============================================================
    // STEP 3: HANDLE CUSTOMER (Supaya tidak error Foreign Key)
    // ============================================================
    var customer models.Customer

    // Perhatikan: Pakai 'h.db' (huruf kecil), bukan 'h.DB'
    result := h.db.Where("name = ?", req.CustomerName).First(&customer)

    if result.Error != nil {
        // Kalau Customer belum ada, kita buat baru
        customer = models.Customer{
            Name: req.CustomerName,
        }
        if err := h.db.Create(&customer).Error; err != nil {
            fmt.Println("❌ ERROR CREATE CUSTOMER:", err)
            return c.Status(500).JSON(fiber.Map{"error": "Failed to create customer"})
        }
    }

    // ============================================================
    // SIMPAN PESAN
    // ============================================================
    message := models.Message{
        CustomerID:   customer.ID, 
        CustomerName: req.CustomerName,
        Content:      req.Content,
        
        // Perbaikan akses Map (Pakai kurung siku dan kunci string)
        Sentiment:    fmt.Sprintf("%v", analysis["sentiment"]),
        Category:     fmt.Sprintf("%v", analysis["category"]),
        Priority:     fmt.Sprintf("%v", analysis["priority"]),
        UrgencyLevel: fmt.Sprintf("%v", analysis["urgency_level"]),
    }

    if err := h.db.Create(&message).Error; err != nil {
        fmt.Println("❌ ERROR SAVE MESSAGE:", err)
        return c.Status(500).JSON(fiber.Map{"error": "Failed to save message"})
    }

    return c.Status(201).JSON(message)
}

func (h *MessageHandler) GetMessages(c *fiber.Ctx) error {
    var messages []models.Message
    
    query := h.db.Order("created_at DESC")
    
    // Filter by priority if specified
    if priority := c.Query("priority"); priority != "" {
        query = query.Where("priority = ?", priority)
    }

    if err := query.Find(&messages).Error; err != nil {
        return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch messages"})
    }

    return c.JSON(fiber.Map{"data": messages})
}

func (h *MessageHandler) GetMessageByID(c *fiber.Ctx) error {
    id, _ := strconv.Atoi(c.Params("id"))
    
    var message models.Message
    if err := h.db.First(&message, id).Error; err != nil {
        return c.Status(404).JSON(fiber.Map{"error": "Message not found"})
    }

    return c.JSON(fiber.Map{"data": message})
}

func (h *MessageHandler) GetSummary(c *fiber.Ctx) error {
    id, _ := strconv.Atoi(c.Params("id"))
    
    var message models.Message
    if err := h.db.First(&message, id).Error; err != nil {
        return c.Status(404).JSON(fiber.Map{"error": "Message not found"})
    }

    summary, err := h.gemini.SummarizeConversation([]string{message.Content})
    if err != nil {
        return c.Status(500).JSON(fiber.Map{"error": "Failed to generate summary"})
    }

    return c.JSON(fiber.Map{"summary": summary})
}

func (h *MessageHandler) SuggestReply(c *fiber.Ctx) error {
    id, _ := strconv.Atoi(c.Params("id"))
    
    var message models.Message
    if err := h.db.First(&message, id).Error; err != nil {
        return c.Status(404).JSON(fiber.Map{"error": "Pesan tidak ditemukan"})
    }

    // Pass sentiment AND category untuk context yang lebih baik
    suggestion, err := h.gemini.SuggestResponse(
        message.Content, 
        message.Sentiment,
        message.Category,  // Added!
    )
    if err != nil {
        return c.Status(500).JSON(fiber.Map{"error": "Gagal generate saran balasan"})
    }

    // Cache the suggestion
    h.db.Model(&models.AIAnalysis{}).
        Where("message_id = ?", message.ID).
        Update("suggested_response", suggestion)

    return c.JSON(fiber.Map{
        "suggested_response": suggestion,
        "context": fiber.Map{
            "sentiment": message.Sentiment,
            "category": message.Category,
        },
    })
}


