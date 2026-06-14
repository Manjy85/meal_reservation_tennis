package com.example.myapplication.meal_reservation

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.example.myapplication.R
import java.util.Locale

class OrdersAdapter(
    private val orders: List<MealReservationLocalStore.OrderHistoryEntry>,
    private val onClick: (MealReservationLocalStore.OrderHistoryEntry) -> Unit
) : RecyclerView.Adapter<OrdersAdapter.OrderViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): OrderViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_meal_reservation_restaurateur_order, parent, false)
        return OrderViewHolder(view)
    }

    override fun onBindViewHolder(holder: OrderViewHolder, position: Int) {
        val item = orders[position]
        holder.reservationNumber.text = item.reservationNumber
        holder.dateService.text = "${item.date.ifBlank { "-" }} | ${item.service.ifBlank { "-" }}"
        holder.status.text = item.status
        holder.total.text = String.format(Locale.FRANCE, "%.2f EUR", item.total)
        holder.itemView.setOnClickListener { onClick(item) }
    }

    override fun getItemCount(): Int = orders.size

    class OrderViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val reservationNumber: TextView = view.findViewById(R.id.textItemReservationNumber)
        val dateService: TextView = view.findViewById(R.id.textItemDateService)
        val status: TextView = view.findViewById(R.id.textItemStatus)
        val total: TextView = view.findViewById(R.id.textItemTotal)
    }
}