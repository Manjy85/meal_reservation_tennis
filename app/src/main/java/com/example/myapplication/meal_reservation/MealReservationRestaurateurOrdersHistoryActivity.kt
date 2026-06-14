package com.example.myapplication.meal_reservation

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.example.myapplication.R

class MealReservationRestaurateurOrdersHistoryActivity : AppCompatActivity() {

    private lateinit var recyclerViewOrders: RecyclerView
    private lateinit var emptyView: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.meal_reservation_restaurateur_orders_history)

        recyclerViewOrders = findViewById(R.id.recyclerViewOrdersHistory)
        emptyView = findViewById(R.id.textViewOrdersHistoryEmpty)
        recyclerViewOrders.layoutManager = LinearLayoutManager(this)

        renderOrders()
    }

    override fun onResume() {
        super.onResume()
        renderOrders()
    }

    private fun renderOrders() {
        val orders = MealReservationLocalStore.getOrdersHistory(this)
            .filter { it.status == "Remise" }
        recyclerViewOrders.adapter = OrdersAdapter(orders) { selectedOrder ->
            startActivity(
                Intent(this, MealReservationRestaurateurOrderDetailActivity::class.java).apply {
                    putExtra(MealReservationRestaurateurOrdersListActivity.EXTRA_RESERVATION_NUMBER, selectedOrder.reservationNumber)
                }
            )
        }
        emptyView.visibility = if (orders.isEmpty()) View.VISIBLE else View.GONE
    }
}

