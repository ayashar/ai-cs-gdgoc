package main

import (
	"ai-support-backend/handlers"
	"ai-support-backend/models"
	"ai-support-backend/services"
	"fmt"
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	jwtware "github.com/gofiber/jwt/v3"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	// 1. Load Environment Variables
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using system environment")
	}

	// 2. Database Connection
	dsn := os.Getenv("DATABASE_URL")
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	fmt.Println("✅ Database connected successfully")

	// 3. Auto Migration
	db.AutoMigrate(&models.User{}, &models.Customer{}, &models.Message{}, &models.AIAnalysis{})
	fmt.Println("✅ Database migration completed")

	// 4. Initialize Services
	geminiService, err := services.NewGeminiService()
	if err != nil {
		log.Fatal("Failed to initialize Gemini service:", err)
	}
	defer geminiService.Close()

	// 5. Initialize Handlers
	authHandler := handlers.NewAuthHandler(db)
	messageHandler := handlers.NewMessageHandler(db, geminiService)

	// 6. Setup Fiber App
	app := fiber.New()

	// Middleware
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
	}))

	// --- ROUTES ---
	
	// 7. API Routes (Selalu prioritaskan rute API di atas rute statis)
	api := app.Group("/api")
	
	// Public Routes
	api.Post("/register", authHandler.Register)
	api.Post("/login", authHandler.Login)

	// JWT Protected Routes (separate group with middleware)
	protected := app.Group("/api")
	protected.Use(jwtware.New(jwtware.Config{
		SigningKey: []byte(os.Getenv("JWT_SECRET")),
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":   "Unauthorized",
				"message": "Invalid or expired token",
			})
		},
	}))
	
	protected.Post("/messages", messageHandler.CreateMessage)
	protected.Get("/messages", messageHandler.GetMessages)
	protected.Get("/messages/:id", messageHandler.GetMessageByID)
	protected.Get("/messages/:id/summary", messageHandler.GetSummary)
	protected.Post("/messages/:id/suggest-reply", messageHandler.SuggestReply)

	// --- SERVE FLUTTER WEB ---

	// 8. Serve Static Files dari folder 'public' di dalam backend
	// Pastikan kamu sudah cp -r frontend/build/web/* backend/public/
	app.Static("/", "./public")

	// 9. Handle SPA (Single Page Application)
	// Jika user akses domain.com/dashboard, Fiber akan kirim index.html-nya Flutter
	app.Get("/*", func(c *fiber.Ctx) error {
		return c.SendFile("./public/index.html")
	})

	// 10. Start Server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	fmt.Printf("🚀 Alex.ai is running on port %s\n", port)
	log.Fatal(app.Listen(":" + port))
}