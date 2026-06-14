package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.ImageButton
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.example.myapplication.MainActivity
import com.example.myapplication.R

class MealReservationRestaurateurOrdersListActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_RESERVATION_NUMBER = "extra_reservation_number"
    }

    private lateinit var recyclerViewOrders: RecyclerView
    private lateinit var emptyView: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_restaurateur_orders_list)

        recyclerViewOrders = findViewById(R.id.recyclerViewOrders)
        emptyView = findViewById(R.id.textViewOrdersEmpty)
        recyclerViewOrders.layoutManager = LinearLayoutManager(this)

        renderOrders()

        findViewById<ImageButton>(R.id.btnLogoutOrders).setOnClickListener {
            startActivity(Intent(this, MainActivity::class.java))
            finish()
        }

        findViewById<Button>(R.id.btnOrdersHistory).setOnClickListener {
            startActivity(Intent(this, MealReservationRestaurateurOrdersHistoryActivity::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        renderOrders()
    }

    private fun renderOrders() {
        val orders = MealReservationLocalStore.getOrdersHistory(this)
            .filter { it.status != "Remise" }
        recyclerViewOrders.adapter = OrdersAdapter(orders) { selectedOrder ->
            startActivity(
                Intent(this, MealReservationRestaurateurOrderDetailActivity::class.java).apply {
                    putExtra(EXTRA_RESERVATION_NUMBER, selectedOrder.reservationNumber)
                }
            )
        }
        emptyView.visibility = if (orders.isEmpty()) View.VISIBLE else View.GONE
    }

}
