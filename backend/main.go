package main

import (
	"ai-support-backend/handlers"
	"ai-support-backend/models"
	"ai-support-backend/services"
	"fmt"
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	jwtware "github.com/gofiber/jwt/v3"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	// 1. Load Environment Variables
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found")
	}

	// 2. Database Connection
	dsn := os.Getenv("DATABASE_URL")
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	fmt.Println("✅ Database connected successfully")

	// 3. Auto Migration (Membuat tabel otomatis sesuai struct di models)
	// Ini menghemat waktu kamu agar tidak perlu create table manual di SQL
	err = db.AutoMigrate(
		&models.User{},
		&models.Customer{},
		&models.Message{},
		&models.AIAnalysis{},
	)
	if err != nil {
		log.Fatal("Database migration failed:", err)
	}
	fmt.Println("✅ Database migration completed")

	// 4. Initialize Services
	geminiService, err := services.NewGeminiService()
	if err != nil {
		log.Fatal("Failed to initialize Gemini service:", err)
	}
	defer geminiService.Close()
	fmt.Println("✅ Gemini AI service initialized")

	// 5. Initialize Handlers
	authHandler := handlers.NewAuthHandler(db)
	messageHandler := handlers.NewMessageHandler(db, geminiService)

	// 6. Setup Fiber App
	app := fiber.New()

	// Middleware
	app.Use(logger.New()) // Logging request masuk
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*", // Allow semua origin agar Flutter (web/mobile) tidak kena block
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
	}))

	// 7. Define Routes
	api := app.Group("/api")

	// Auth Routes
	api.Post("/register", authHandler.Register)
	api.Post("/login", authHandler.Login)

	api.Use(jwtware.New(jwtware.Config{
		SigningKey: []byte(os.Getenv("JWT_SECRET")),
		ErrorHandler: func(c *fiber.Ctx, err error) error{
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Unauthorized",
				"message": "Invalid or expired token",
			})
		},
	}))
	// Message Routes
	api.Post("/messages", messageHandler.CreateMessage)           // Ingest pesan baru (Simulasi Customer kirim pesan)
	api.Get("/messages", messageHandler.GetMessages)              // Inbox List
	api.Get("/messages/:id", messageHandler.GetMessageByID)       // Detail Pesan
	api.Get("/messages/:id/summary", messageHandler.GetSummary)   // Fitur Summary
	api.Post("/messages/:id/suggest-reply", messageHandler.SuggestReply) // Fitur Suggestion

	// 8. Start Server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	fmt.Printf("🚀 Server running on port %s\n", port)
	log.Fatal(app.Listen(":" + port))
}

