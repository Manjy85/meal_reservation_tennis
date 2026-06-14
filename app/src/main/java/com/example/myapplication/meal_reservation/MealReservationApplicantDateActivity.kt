package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.DatePicker
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.R

class MealReservationApplicantDateActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_SELECTED_DATE = "extra_selected_date"
        const val EXTRA_SELECTED_SERVICE = "extra_selected_service"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_applicant_date)

        val datePicker = findViewById<DatePicker>(R.id.datePickerEvent)
        val radioGroupService = findViewById<RadioGroup>(R.id.radioGroupService)

        findViewById<Button>(R.id.btnContinueToCatalog).setOnClickListener {
            if (radioGroupService.checkedRadioButtonId == -1) {
                Toast.makeText(this, "Selectionne Midi ou Soir pour continuer", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val day = datePicker.dayOfMonth.toString().padStart(2, '0')
            val month = (datePicker.month + 1).toString().padStart(2, '0')
            val year = datePicker.year
            val selectedDate = "$day/$month/$year"

            val selectedService = findViewById<RadioButton>(radioGroupService.checkedRadioButtonId)
                .text
                .toString()

            startActivity(
                Intent(this, MealReservationApplicantProductCatalogueActivity::class.java).apply {
                    putExtra(EXTRA_SELECTED_DATE, selectedDate)
                    putExtra(EXTRA_SELECTED_SERVICE, selectedService)
                }
            )
        }
    }
}
