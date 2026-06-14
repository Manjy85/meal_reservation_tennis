package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ImageButton
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.MainActivity
import com.example.myapplication.R
import java.util.Locale

class MealReservationRestaurateurOrderDetailActivity : AppCompatActivity() {

    private val statuses = listOf("En attente", "En preparation", "Prete", "Remise")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_restaurateur_order_detail)

        val reservationNumber = intent.getStringExtra(MealReservationRestaurateurOrdersListActivity.EXTRA_RESERVATION_NUMBER).orEmpty()
        val order = MealReservationLocalStore.findOrderByReservationNumber(this, reservationNumber)

        val textReservationNumber = findViewById<TextView>(R.id.textViewReservationNumber)
        val textClientIdentity = findViewById<TextView>(R.id.textViewClientIdentity)
        val textOrderDateService = findViewById<TextView>(R.id.textViewOrderDateService)
        val textOrderItems = findViewById<TextView>(R.id.textViewOrderItems)
        val textOrderTotal = findViewById<TextView>(R.id.textViewOrderTotal)
        val spinnerStatus = findViewById<Spinner>(R.id.spinnerOrderStatus)

        spinnerStatus.adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, statuses)

        if (order == null) {
            textReservationNumber.text = "Reservation: introuvable"
            textClientIdentity.text = "Client: -"
            textOrderDateService.text = "Date: - | Service: -"
            textOrderItems.text = "- Aucun article"
            textOrderTotal.text = "Total: 0,00 EUR"
            findViewById<Button>(R.id.btnUpdateOrderStatus).isEnabled = false
        } else {
            textReservationNumber.text = "Reservation: ${order.reservationNumber}"
            val identity = listOf(order.clientName, order.email, order.clientPhone)
                .filter { it.isNotBlank() }
                .joinToString(" - ")
                .ifBlank { "-" }
            textClientIdentity.text = "Client: $identity"
            textOrderDateService.text = "Date: ${order.date.ifBlank { "-" }} | Service: ${order.service.ifBlank { "-" }}"
            textOrderItems.text = if (order.products.isEmpty()) "- Aucun article" else order.products.joinToString("\n") { "- $it" }
            textOrderTotal.text = "Total: ${String.format(Locale.FRANCE, "%.2f EUR", order.total)}"

            val selectedIndex = statuses.indexOf(order.status).takeIf { it >= 0 } ?: 0
            spinnerStatus.setSelection(selectedIndex)
        }

        findViewById<Button>(R.id.btnUpdateOrderStatus).setOnClickListener {
            if (order == null) return@setOnClickListener
            val newStatus = spinnerStatus.selectedItem.toString()
            MealReservationLocalStore.updateOrderStatus(this, order.reservationNumber, newStatus)
            Toast.makeText(this, "Statut mis a jour", Toast.LENGTH_SHORT).show()
            finish()
        }

        findViewById<ImageButton>(R.id.btnLogoutOrderDetail).setOnClickListener {
            startActivity(Intent(this, MainActivity::class.java))
            finish()
        }
    }
}
