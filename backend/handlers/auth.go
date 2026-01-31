package handlers

import (
    "ai-support-backend/models"
    "os"
    "time"

    "github.com/gofiber/fiber/v2"
    "github.com/golang-jwt/jwt/v5"
    "golang.org/x/crypto/bcrypt"
    "gorm.io/gorm"
)

type AuthHandler struct {
    db *gorm.DB
}

func NewAuthHandler(db *gorm.DB) *AuthHandler {
    return &AuthHandler{db: db}
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
    var req models.RegisterRequest
    if err := c.BodyParser(&req); err != nil {
        return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
    }

    hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
    
    user := models.User{
        Email:        req.Email,
        PasswordHash: string(hash),
        Name:         req.Name,
        Role:         "agent",
    }

    if err := h.db.Create(&user).Error; err != nil {
        return c.Status(400).JSON(fiber.Map{"error": "Email already exists"})
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "user_id": user.ID,
        "email":   user.Email,
        "exp":     time.Now().Add(24 * time.Hour).Unix(),
    })

    tokenString, _ := token.SignedString([]byte(os.Getenv("JWT_SECRET")))

    return c.JSON(fiber.Map{
        "token": tokenString,
        "user":  user,
    })
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
    var req models.LoginRequest
    if err := c.BodyParser(&req); err != nil {
        return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
    }

    var user models.User
    if err := h.db.Where("email = ?", req.Email).First(&user).Error; err != nil {
        return c.Status(401).JSON(fiber.Map{"error": "Invalid credentials"})
    }

    if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
        return c.Status(401).JSON(fiber.Map{"error": "Invalid credentials"})
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "user_id": user.ID,
        "email":   user.Email,
        "exp":     time.Now().Add(24 * time.Hour).Unix(),
    })

    tokenString, _ := token.SignedString([]byte(os.Getenv("JWT_SECRET")))

    return c.JSON(fiber.Map{
        "token": tokenString,
        "user":  user,
    })
}
