package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.R
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

class MealReservationApplicantNumActivity : AppCompatActivity() {

    private data class RecapItem(val name: String, val qty: Int, val unitPrice: Double)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_applicant_num)

        val textReservationNumber = findViewById<TextView>(R.id.textReservationNumber)
        val textSummaryIdentity = findViewById<TextView>(R.id.textSummaryIdentity)
        val textSummaryDate = findViewById<TextView>(R.id.textSummaryDate)
        val textSummaryService = findViewById<TextView>(R.id.textSummaryService)
        val textSummaryProducts = findViewById<TextView>(R.id.textSummaryProducts)
        val textSummaryTotalTtc = findViewById<TextView>(R.id.textSummaryTotalTtc)

        val selectedDate = intent.getStringExtra(MealReservationApplicantReservationBasketActivity.EXTRA_SELECTED_DATE).orEmpty()
        val selectedService = intent.getStringExtra(MealReservationApplicantReservationBasketActivity.EXTRA_SELECTED_SERVICE).orEmpty()
        val names = intent.getStringArrayListExtra(MealReservationApplicantReservationBasketActivity.EXTRA_PRODUCT_NAMES) ?: arrayListOf()
        val qties = intent.getIntArrayExtra(MealReservationApplicantReservationBasketActivity.EXTRA_PRODUCT_QTIES) ?: intArrayOf()
        val prices = intent.getDoubleArrayExtra(MealReservationApplicantReservationBasketActivity.EXTRA_PRODUCT_UNIT_PRICES) ?: doubleArrayOf()

        val recapItems = buildRecapItems(names, qties, prices)
        val total = recapItems.sumOf { it.qty * it.unitPrice }

        val reservationNumber = MealReservationLocalStore.nextReservationNumber(this)
        textReservationNumber.text = reservationNumber

        val account = MealReservationLocalStore.getCurrentAccount(this)
        val identityText = if (account != null) {
            "Identite: ${account.firstName} ${account.lastName} - ${account.email} - ${account.phone}"
        } else {
            "Identite: compte non trouve"
        }
        textSummaryIdentity.text = identityText
        textSummaryDate.text = "Date: ${selectedDate.ifBlank { "-" }}"
        textSummaryService.text = "Service: ${selectedService.ifBlank { "-" }}"
        textSummaryProducts.text = buildProductsSummary(recapItems)
        textSummaryTotalTtc.text = "Total TTC: ${formatEur(total)}"

        MealReservationLocalStore.saveOrderHistory(
            this,
            JSONObject().apply {
                put("reservationNumber", reservationNumber)
                put("date", selectedDate)
                put("service", selectedService)
                put("total", total)
                put("email", account?.email ?: "")
                put("clientName", listOf(account?.firstName, account?.lastName).filterNot { it.isNullOrBlank() }.joinToString(" "))
                put("clientPhone", account?.phone ?: "")
                put("status", "En attente")
                put("products", JSONArray().apply {
                    recapItems.forEach { item ->
                        put(
                            JSONObject().apply {
                                put("name", item.name)
                                put("qty", item.qty)
                                put("unitPrice", item.unitPrice)
                            }
                        )
                    }
                })
            }
        )

        findViewById<Button>(R.id.btnBackHome).setOnClickListener {
            startActivity(Intent(this, MealReservationApplicantLoginActivity::class.java))
        }
    }

    private fun buildRecapItems(names: List<String>, qties: IntArray, prices: DoubleArray): List<RecapItem> {
        val size = minOf(names.size, qties.size, prices.size)
        val items = mutableListOf<RecapItem>()
        for (i in 0 until size) {
            if (qties[i] > 0) items.add(RecapItem(names[i], qties[i], prices[i]))
        }
        return items
    }

    private fun buildProductsSummary(items: List<RecapItem>): String {
        if (items.isEmpty()) return "Produits:\n- Aucun produit"
        val lines = items.joinToString("\n") { item ->
            "- ${item.name} x${item.qty} = ${formatEur(item.qty * item.unitPrice)}"
        }
        return "Produits:\n$lines"
    }

    private fun formatEur(amount: Double): String = String.format(Locale.FRANCE, "%.2f EUR", amount)
}