package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.ImageButton
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.MainActivity
import com.example.myapplication.R

class MealReservationRestaurateurDashboardActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_restaurateur_dashboard)

        findViewById<Button>(R.id.btnGoCatalogueManagement).setOnClickListener {
            startActivity(Intent(this, MealReservationRestaurateurCatalogManagementActivity::class.java))
        }

        findViewById<Button>(R.id.btnGoScheduleManagement).setOnClickListener {
            startActivity(Intent(this, MealReservationRestaurateurScheduleManagementActivity::class.java))
        }

        findViewById<Button>(R.id.btnGoOrdersManagement).setOnClickListener {
            startActivity(Intent(this, MealReservationRestaurateurOrdersListActivity::class.java))
        }

        findViewById<ImageButton>(R.id.btnLogoutDashboard).setOnClickListener {
            startActivity(Intent(this, MainActivity::class.java))
            finish()
        }
    }
}

