package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.ImageButton
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.MainActivity
import com.example.myapplication.R

class MealReservationRestaurateurCatalogManagementActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_restaurateur_catalog_management)

        findViewById<Button>(R.id.btnAddProduct).setOnClickListener {
            startActivity(Intent(this, MealReservationRestaurateurProductFormActivity::class.java))
        }

        findViewById<ImageButton>(R.id.btnLogoutCatalogueManagement).setOnClickListener {
            startActivity(Intent(this, MainActivity::class.java))
            finish()
        }
    }
}

