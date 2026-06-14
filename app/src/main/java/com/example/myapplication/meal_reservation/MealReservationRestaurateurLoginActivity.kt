package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.R

class MealReservationRestaurateurLoginActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_restaurateur_login)

        val usernameField = findViewById<EditText>(R.id.editTextRestaurateurUsername)
        val passwordField = findViewById<EditText>(R.id.editTextRestaurateurPassword)

        findViewById<Button>(R.id.btnRestaurateurLogin).setOnClickListener {
            val username = usernameField.text.toString().trim()
            val password = passwordField.text.toString().trim()

            usernameField.error = null
            passwordField.error = null

            if (username == ADMIN_USERNAME && password == ADMIN_PASSWORD) {
                startActivity(Intent(this, MealReservationRestaurateurDashboardActivity::class.java))
            } else {
                passwordField.error = "Identifiants invalides"
                passwordField.requestFocus()
            }
        }
    }

    companion object {
        private const val ADMIN_USERNAME = "admin"
        private const val ADMIN_PASSWORD = "admin"
    }
}
