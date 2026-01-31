package models

import "time"

type User struct {
    ID           uint      `json:"id" gorm:"primaryKey"`
    Email        string    `json:"email" gorm:"unique;not null"`
    PasswordHash string    `json:"-" gorm:"not null"`
    Name         string    `json:"name"`
    Role         string    `json:"role" gorm:"default:'agent'"`
    CreatedAt    time.Time `json:"created_at"`
}

type Customer struct {
    ID        uint      `json:"id" gorm:"primaryKey"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    CreatedAt time.Time `json:"created_at"`
}

type Message struct {
    ID           uint      `json:"id" gorm:"primaryKey"`
    CustomerID   uint      `json:"customer_id"`
    CustomerName string    `json:"customer_name"`
    Content      string    `json:"content" gorm:"type:text"`
    Sentiment    string    `json:"sentiment"`
    Category     string    `json:"category"`
    Priority     string    `json:"priority"`
    UrgencyLevel string    `json:"urgency_level"`
    CreatedAt    time.Time `json:"created_at"`
    
    // Relations
    Customer Customer `json:"customer,omitempty" gorm:"foreignKey:CustomerID"`
}

type AIAnalysis struct {
    ID                uint      `json:"id" gorm:"primaryKey"`
    MessageID         uint      `json:"message_id"`
    Summary           string    `json:"summary" gorm:"type:text"`
    SuggestedResponse string    `json:"suggested_response" gorm:"type:text"`
    SentimentScore    float64   `json:"sentiment_score"`
    CreatedAt         time.Time `json:"created_at"`
}

// DTOs
type LoginRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required"`
}

type RegisterRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required,min=6"`
    Name     string `json:"name" validate:"required"`
}

type CreateMessageRequest struct {
    CustomerName string `json:"customer_name" validate:"required"`
    Content      string `json:"content" validate:"required"`
}

type AIAnalysisResponse struct {
    Sentiment    string  `json:"sentiment"`
    Category     string  `json:"category"`
    Priority     string  `json:"priority"`
    UrgencyLevel string  `json:"urgency_level"`
    Score        float64 `json:"score"`
}

