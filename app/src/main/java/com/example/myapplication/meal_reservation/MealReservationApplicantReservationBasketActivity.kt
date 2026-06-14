package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.R
import java.util.Locale

class MealReservationApplicantReservationBasketActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_SELECTED_DATE = "extra_selected_date"
        const val EXTRA_SELECTED_SERVICE = "extra_selected_service"
        const val EXTRA_PRODUCT_NAMES = "extra_product_names"
        const val EXTRA_PRODUCT_QTIES = "extra_product_qties"
        const val EXTRA_PRODUCT_UNIT_PRICES = "extra_product_unit_prices"
    }

    private data class BasketItem(
        val name: String,
        val unitPrice: Double,
        var qty: Int
    )

    private lateinit var itemsContainer: LinearLayout
    private lateinit var textViewOrderTotal: TextView
    private lateinit var textViewEmptyBasket: TextView
    private lateinit var textViewSelectedDate: TextView
    private lateinit var textViewSelectedService: TextView
    private lateinit var btnValidateOrder: Button
    private val basketItems = mutableListOf<BasketItem>()
    private var selectedDate: String = ""
    private var selectedService: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_applicant_reservation_basket)

        itemsContainer = findViewById(R.id.basketItemsContainer)
        textViewOrderTotal = findViewById(R.id.textViewOrderTotal)
        textViewEmptyBasket = findViewById(R.id.textViewEmptyBasket)
        textViewSelectedDate = findViewById(R.id.textViewSelectedDate)
        textViewSelectedService = findViewById(R.id.textViewSelectedService)
        btnValidateOrder = findViewById(R.id.btnValidateOrder)

        loadItemsFromIntent()
        refreshBasketUi()

        btnValidateOrder.setOnClickListener {
            if (basketItems.isEmpty()) {
                Toast.makeText(this, "Ton panier est vide", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            startActivity(Intent(this, MealReservationApplicantNumActivity::class.java).apply {
                putExtra(EXTRA_SELECTED_DATE, selectedDate)
                putExtra(EXTRA_SELECTED_SERVICE, selectedService)
                putStringArrayListExtra(EXTRA_PRODUCT_NAMES, ArrayList(basketItems.map { it.name }))
                putExtra(EXTRA_PRODUCT_QTIES, basketItems.map { it.qty }.toIntArray())
                putExtra(EXTRA_PRODUCT_UNIT_PRICES, basketItems.map { it.unitPrice }.toDoubleArray())
            })
        }
    }

    private fun loadItemsFromIntent() {
        selectedDate = intent.getStringExtra(EXTRA_SELECTED_DATE).orEmpty()
        selectedService = intent.getStringExtra(EXTRA_SELECTED_SERVICE).orEmpty()
        textViewSelectedDate.text = if (selectedDate.isBlank()) "Date choisie: -" else "Date choisie: $selectedDate"
        textViewSelectedService.text = if (selectedService.isBlank()) "Service: -" else "Service: $selectedService"

        val names = intent.getStringArrayListExtra(EXTRA_PRODUCT_NAMES) ?: arrayListOf()
        val qties = intent.getIntArrayExtra(EXTRA_PRODUCT_QTIES) ?: intArrayOf()
        val prices = intent.getDoubleArrayExtra(EXTRA_PRODUCT_UNIT_PRICES) ?: doubleArrayOf()

        val size = minOf(names.size, qties.size, prices.size)
        basketItems.clear()
        for (i in 0 until size) {
            if (qties[i] > 0) {
                basketItems.add(BasketItem(name = names[i], unitPrice = prices[i], qty = qties[i]))
            }
        }
    }

    private fun refreshBasketUi() {
        itemsContainer.removeAllViews()

        basketItems.forEach { item ->
            val row = LayoutInflater.from(this)
                .inflate(R.layout.item_meal_reservation_basket_product, itemsContainer, false)

            val textName = row.findViewById<TextView>(R.id.textBasketName)
            val textUnitPrice = row.findViewById<TextView>(R.id.textBasketUnitPrice)
            val textQty = row.findViewById<TextView>(R.id.textQtyBasket)
            val textSubtotal = row.findViewById<TextView>(R.id.textSubtotalBasket)
            val btnMinus = row.findViewById<Button>(R.id.btnMinusBasket)
            val btnPlus = row.findViewById<Button>(R.id.btnPlusBasket)
            val btnDelete = row.findViewById<Button>(R.id.btnDeleteBasket)

            textName.text = item.name
            textUnitPrice.text = "Prix unitaire: ${formatEur(item.unitPrice)}"
            textQty.text = item.qty.toString()
            textSubtotal.text = "Sous-total: ${formatEur(item.qty * item.unitPrice)}"

            btnMinus.setOnClickListener {
                if (item.qty > 1) item.qty -= 1 else basketItems.remove(item)
                refreshBasketUi()
            }
            btnPlus.setOnClickListener {
                item.qty += 1
                refreshBasketUi()
            }
            btnDelete.setOnClickListener {
                basketItems.remove(item)
                refreshBasketUi()
            }

            itemsContainer.addView(row)
        }

        val total = basketItems.sumOf { it.qty * it.unitPrice }
        textViewOrderTotal.text = "Total general: ${formatEur(total)}"

        val hasItems = basketItems.isNotEmpty()
        textViewEmptyBasket.visibility = if (hasItems) TextView.GONE else TextView.VISIBLE
        btnValidateOrder.isEnabled = hasItems
        btnValidateOrder.alpha = if (hasItems) 1f else 0.6f
    }

    private fun formatEur(amount: Double): String = String.format(Locale.FRANCE, "%.2f EUR", amount)
}
