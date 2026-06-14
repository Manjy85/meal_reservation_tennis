package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.util.Patterns
import android.widget.Button
import android.widget.EditText
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.R
import org.json.JSONArray

class MealReservationApplicantLoginActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_applicant_login)

        val emailField = findViewById<EditText>(R.id.editLoginEmail)
        val passwordField = findViewById<EditText>(R.id.editLoginPassword)

        findViewById<Button>(R.id.btnClientLogin).setOnClickListener {
            val email = emailField.text.toString().trim()
            val password = passwordField.text.toString().trim()

            emailField.error = null
            passwordField.error = null

            when {
                email.isEmpty() -> {
                    emailField.error = "Email requis"
                    emailField.requestFocus()
                }
                !Patterns.EMAIL_ADDRESS.matcher(email).matches() -> {
                    emailField.error = "Email invalide"
                    emailField.requestFocus()
                }
                password.isEmpty() -> {
                    passwordField.error = "Mot de passe requis"
                    passwordField.requestFocus()
                }
                !isValidLocalLogin(email, password) -> {
                    passwordField.error = "Identifiants incorrects"
                    passwordField.requestFocus()
                }
                else -> {
                    MealReservationLocalStore.setCurrentAccountEmail(this, email)
                    startActivity(Intent(this, MealReservationApplicantDateActivity::class.java))
                }
            }
        }

        findViewById<Button>(R.id.btnGoToSignup).setOnClickListener {
            startActivity(Intent(this, MealReservationApplicantIdentificationActivity::class.java))
        }
    }

    private fun isValidLocalLogin(email: String, password: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val accountsRaw = prefs.getString(KEY_ACCOUNTS, null) ?: return false
        val accounts = try {
            JSONArray(accountsRaw)
        } catch (_: Exception) {
            return false
        }

        for (i in 0 until accounts.length()) {
            val account = accounts.optJSONObject(i) ?: continue
            val accountEmail = account.optString("email")
            if (!accountEmail.equals(email, ignoreCase = true)) continue

            // Compatibilite: password si present, sinon telephone (comptes deja crees)
            val storedPassword = if (account.has("password")) {
                account.optString("password")
            } else {
                account.optString("phone")
            }
            return storedPassword == password
        }
        return false
    }

    companion object {
        private const val PREFS_NAME = "meal_reservation_prefs"
        private const val KEY_ACCOUNTS = "created_accounts"
    }
}
