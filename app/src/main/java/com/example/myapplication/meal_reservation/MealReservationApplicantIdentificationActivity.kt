package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.util.Patterns
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.R
import org.json.JSONArray
import org.json.JSONObject

class MealReservationApplicantIdentificationActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_applicant_identification)

        val firstNameField = findViewById<EditText>(R.id.editFirstName)
        val lastNameField = findViewById<EditText>(R.id.editLastName)
        val emailField = findViewById<EditText>(R.id.editEmail)
        val phoneField = findViewById<EditText>(R.id.editPhone)
        val passwordField = findViewById<EditText>(R.id.editPassword)

        findViewById<Button>(R.id.btnSubmit).setOnClickListener {
            val firstName = firstNameField.text.toString().trim()
            val lastName = lastNameField.text.toString().trim()
            val email = emailField.text.toString().trim()
            val phone = phoneField.text.toString().trim()
            val password = passwordField.text.toString().trim()

            firstNameField.error = null
            lastNameField.error = null
            emailField.error = null
            phoneField.error = null
            passwordField.error = null

            when {
                firstName.isEmpty() -> {
                    firstNameField.error = "Prénom requis"
                    firstNameField.requestFocus()
                }
                lastName.isEmpty() -> {
                    lastNameField.error = "Nom requis"
                    lastNameField.requestFocus()
                }
                !isValidEmail(email) -> {
                    emailField.error = "Adresse e-mail invalide"
                    emailField.requestFocus()
                }
                !isValidPhone(phone) -> {
                    phoneField.error = "Numéro invalide (10 chiffres, ex. 0612345678)"
                    phoneField.requestFocus()
                }
                password.length < 6 -> {
                    passwordField.error = "Mot de passe: 6 caractères minimum"
                    passwordField.requestFocus()
                }
                else -> {
                    saveAccountLocally(firstName, lastName, email, phone, password)
                    MealReservationLocalStore.setCurrentAccountEmail(this, email)
                    Toast.makeText(this, "Compte enregistré", Toast.LENGTH_SHORT).show()
                    startActivity(Intent(this, MealReservationApplicantDateActivity::class.java))
                }
            }
        }
    }

    private fun isValidEmail(email: String): Boolean {
        return Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }

    private fun isValidPhone(phone: String): Boolean {
        return Regex("^0\\d{9}$").matches(phone)
    }

    private fun saveAccountLocally(
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        password: String
    ) {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val accounts = getStoredAccounts(prefs.getString(KEY_ACCOUNTS, null))

        val account = JSONObject().apply {
            put("firstName", firstName)
            put("lastName", lastName)
            put("email", email)
            put("phone", phone)
            put("password", password)
        }

        var replaced = false
        for (i in 0 until accounts.length()) {
            val current = accounts.optJSONObject(i) ?: continue
            if (current.optString("email").equals(email, ignoreCase = true)) {
                accounts.put(i, account)
                replaced = true
                break
            }
        }
        if (!replaced) accounts.put(account)

        prefs.edit().putString(KEY_ACCOUNTS, accounts.toString()).apply()
    }

    private fun getStoredAccounts(raw: String?): JSONArray {
        return try {
            if (raw.isNullOrBlank()) JSONArray() else JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    companion object {
        private const val PREFS_NAME = "meal_reservation_prefs"
        private const val KEY_ACCOUNTS = "created_accounts"
    }
}
