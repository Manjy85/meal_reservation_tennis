package com.example.myapplication.meal_reservation

import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.R

class MealReservationRestaurateurProductFormActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_restaurateur_product_form)

        findViewById<Button>(R.id.btnSaveProduct).setOnClickListener {
            finish()
        }

        findViewById<Button>(R.id.btnDeleteProduct).setOnClickListener {
            finish()
        }
    }
}

