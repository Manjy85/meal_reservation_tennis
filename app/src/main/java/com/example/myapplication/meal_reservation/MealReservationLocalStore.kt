package com.example.myapplication.meal_reservation

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.format.DateTimeFormatter

object MealReservationLocalStore {
    private const val PREFS_NAME = "meal_reservation_prefs"
    private const val KEY_ACCOUNTS = "created_accounts"
    private const val KEY_CURRENT_ACCOUNT_EMAIL = "current_account_email"
    private const val KEY_LAST_ORDER_DAY = "last_order_day"
    private const val KEY_LAST_ORDER_COUNT = "last_order_count"
    private const val KEY_ORDERS_HISTORY = "orders_history"

    private val dayFormatter: DateTimeFormatter = DateTimeFormatter.BASIC_ISO_DATE // yyyyMMdd

    data class Account(
        val firstName: String,
        val lastName: String,
        val email: String,
        val phone: String
    )

    data class OrderHistoryEntry(
        val reservationNumber: String,
        val date: String,
        val service: String,
        val total: Double,
        val email: String,
        val clientName: String,
        val clientPhone: String,
        val status: String,
        val products: List<String>
    )

    fun setCurrentAccountEmail(context: Context, email: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_CURRENT_ACCOUNT_EMAIL, email)
            .apply()
    }

    fun getCurrentAccountEmail(context: Context): String? {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_CURRENT_ACCOUNT_EMAIL, null)
    }

    fun getCurrentAccount(context: Context): Account? {
        val email = getCurrentAccountEmail(context) ?: return null
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_ACCOUNTS, null) ?: return null
        val accounts = try {
            JSONArray(raw)
        } catch (_: Exception) {
            return null
        }

        for (i in 0 until accounts.length()) {
            val account = accounts.optJSONObject(i) ?: continue
            if (!account.optString("email").equals(email, ignoreCase = true)) continue
            return Account(
                firstName = account.optString("firstName"),
                lastName = account.optString("lastName"),
                email = account.optString("email"),
                phone = account.optString("phone")
            )
        }
        return null
    }

    fun nextReservationNumber(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val today = LocalDate.now().format(dayFormatter)
        val storedDay = prefs.getString(KEY_LAST_ORDER_DAY, "") ?: ""
        val nextCount = if (storedDay == today) {
            prefs.getInt(KEY_LAST_ORDER_COUNT, 0) + 1
        } else {
            1
        }

        prefs.edit()
            .putString(KEY_LAST_ORDER_DAY, today)
            .putInt(KEY_LAST_ORDER_COUNT, nextCount)
            .apply()

        return "EVT-$today-${nextCount.toString().padStart(4, '0')}"
    }

    fun saveOrderHistory(context: Context, order: JSONObject) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = prefs.getString(KEY_ORDERS_HISTORY, null)
        val history = try {
            if (existing.isNullOrBlank()) JSONArray() else JSONArray(existing)
        } catch (_: Exception) {
            JSONArray()
        }
        history.put(order)
        prefs.edit().putString(KEY_ORDERS_HISTORY, history.toString()).apply()
    }

    fun getOrdersHistory(context: Context): List<OrderHistoryEntry> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = prefs.getString(KEY_ORDERS_HISTORY, null)
        val history = try {
            if (existing.isNullOrBlank()) JSONArray() else JSONArray(existing)
        } catch (_: Exception) {
            JSONArray()
        }

        val orders = mutableListOf<OrderHistoryEntry>()
        for (i in 0 until history.length()) {
            val order = history.optJSONObject(i) ?: continue
            val productsJson = order.optJSONArray("products") ?: JSONArray()
            val products = mutableListOf<String>()
            for (p in 0 until productsJson.length()) {
                val product = productsJson.optJSONObject(p) ?: continue
                val name = product.optString("name")
                val qty = product.optInt("qty", 0)
                if (name.isNotBlank() && qty > 0) products.add("$name x$qty")
            }
            orders.add(
                OrderHistoryEntry(
                    reservationNumber = order.optString("reservationNumber"),
                    date = order.optString("date"),
                    service = order.optString("service"),
                    total = order.optDouble("total", 0.0),
                    email = order.optString("email"),
                    clientName = order.optString("clientName"),
                    clientPhone = order.optString("clientPhone"),
                    status = order.optString("status", "En attente"),
                    products = products
                )
            )
        }
        return orders.sortedBy { it.reservationNumber }
    }

    fun findOrderByReservationNumber(context: Context, reservationNumber: String): OrderHistoryEntry? {
        return getOrdersHistory(context).firstOrNull { it.reservationNumber == reservationNumber }
    }

    fun updateOrderStatus(context: Context, reservationNumber: String, status: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existing = prefs.getString(KEY_ORDERS_HISTORY, null)
        val history = try {
            if (existing.isNullOrBlank()) JSONArray() else JSONArray(existing)
        } catch (_: Exception) {
            JSONArray()
        }

        for (i in 0 until history.length()) {
            val order = history.optJSONObject(i) ?: continue
            if (order.optString("reservationNumber") == reservationNumber) {
                order.put("status", status)
                break
            }
        }

        prefs.edit().putString(KEY_ORDERS_HISTORY, history.toString()).apply()
    }
}
