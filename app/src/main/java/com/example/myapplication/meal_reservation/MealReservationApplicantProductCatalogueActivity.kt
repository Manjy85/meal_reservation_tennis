package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.myapplication.R
import java.util.Locale

class MealReservationApplicantProductCatalogueActivity : AppCompatActivity() {

    private data class ProductUi(
        val name: String,
        val unitPrice: Double,
        val qtyView: TextView,
        val subtotalView: TextView,
        val plusBtn: Button,
        val minusBtn: Button,
        var qty: Int = 0
    )

    private lateinit var btnVoirMonPanier: Button
    private lateinit var textViewTotalGeneral: TextView
    private lateinit var products: List<ProductUi>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_applicant_product_catalogue)

        val selectedDate = intent.getStringExtra(MealReservationApplicantDateActivity.EXTRA_SELECTED_DATE).orEmpty()
        val selectedService = intent.getStringExtra(MealReservationApplicantDateActivity.EXTRA_SELECTED_SERVICE).orEmpty()

        btnVoirMonPanier = findViewById(R.id.btnVoirMonPanier)
        textViewTotalGeneral = findViewById(R.id.textViewTotalGeneral)

        products = listOf(
            product("Burger Simple", 8.0, R.id.textQtyBurgerSimple, R.id.textSubtotalBurgerSimple, R.id.btnPlusBurgerSimple, R.id.btnMinusBurgerSimple),
            product("Burger Double", 10.0, R.id.textQtyBurgerDouble, R.id.textSubtotalBurgerDouble, R.id.btnPlusBurgerDouble, R.id.btnMinusBurgerDouble),
            product("Bagel", 7.5, R.id.textQtyBagel, R.id.textSubtotalBagel, R.id.btnPlusBagel, R.id.btnMinusBagel),
            product("Frites", 2.0, R.id.textQtyFrites, R.id.textSubtotalFrites, R.id.btnPlusFrites, R.id.btnMinusFrites),
            product("Boissons", 1.5, R.id.textQtyBoissons, R.id.textSubtotalBoissons, R.id.btnPlusBoissons, R.id.btnMinusBoissons)
        )

        products.forEach { p ->
            p.plusBtn.setOnClickListener {
                p.qty += 1
                refreshProduct(p)
                refreshTotal()
            }
            p.minusBtn.setOnClickListener {
                if (p.qty > 0) {
                    p.qty -= 1
                    refreshProduct(p)
                    refreshTotal()
                }
            }
            refreshProduct(p)
        }

        refreshTotal()

        btnVoirMonPanier.setOnClickListener {
            val selected = products.filter { it.qty > 0 }
            if (selected.isEmpty()) {
                Toast.makeText(this, "Ajoute au moins 1 produit pour voir le panier", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            val basketIntent = Intent(this, MealReservationApplicantReservationBasketActivity::class.java).apply {
                putExtra(MealReservationApplicantReservationBasketActivity.EXTRA_SELECTED_DATE, selectedDate)
                putExtra(MealReservationApplicantReservationBasketActivity.EXTRA_SELECTED_SERVICE, selectedService)
                putStringArrayListExtra(
                    MealReservationApplicantReservationBasketActivity.EXTRA_PRODUCT_NAMES,
                    ArrayList(selected.map { it.name })
                )
                putExtra(
                    MealReservationApplicantReservationBasketActivity.EXTRA_PRODUCT_QTIES,
                    selected.map { it.qty }.toIntArray()
                )
                putExtra(
                    MealReservationApplicantReservationBasketActivity.EXTRA_PRODUCT_UNIT_PRICES,
                    selected.map { it.unitPrice }.toDoubleArray()
                )
            }
            startActivity(basketIntent)
        }
    }

    private fun product(
        name: String,
        unitPrice: Double,
        qtyId: Int,
        subtotalId: Int,
        plusId: Int,
        minusId: Int
    ): ProductUi {
        return ProductUi(
            name = name,
            unitPrice = unitPrice,
            qtyView = findViewById(qtyId),
            subtotalView = findViewById(subtotalId),
            plusBtn = findViewById(plusId),
            minusBtn = findViewById(minusId)
        )
    }

    private fun refreshProduct(product: ProductUi) {
        product.qtyView.text = product.qty.toString()
        val subtotal = product.qty * product.unitPrice
        product.subtotalView.text = "Sous-total: ${formatEur(subtotal)}"
    }

    private fun refreshTotal() {
        val total = products.sumOf { it.qty * it.unitPrice }
        textViewTotalGeneral.text = "Total general: ${formatEur(total)}"
        btnVoirMonPanier.isEnabled = total > 0.0
        btnVoirMonPanier.alpha = if (btnVoirMonPanier.isEnabled) 1f else 0.6f
    }

    private fun formatEur(amount: Double): String {
        return String.format(Locale.FRANCE, "%.2f EUR", amount)
    }
}
