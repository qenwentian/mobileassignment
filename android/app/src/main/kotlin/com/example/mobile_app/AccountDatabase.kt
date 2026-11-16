package com.example.mobile_app

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteConstraintException
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteException
import android.database.sqlite.SQLiteOpenHelper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.GeneralSecurityException
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

internal class AccountDatabase(context: Context) :
    SQLiteOpenHelper(context, context.noBackupFilesDir.resolve("finder_accounts.db").path, null, 1) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE accounts (
                id INTEGER PRIMARY KEY,
                student_id TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                salt BLOB NOT NULL,
                password_hash BLOB NOT NULL
            )
        """.trimIndent())
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "login" -> result.success(login(call))
                "register" -> result.success(register(call))
                else -> result.notImplemented()
            }
        } catch (_: SQLiteConstraintException) {
            result.error("duplicate-account", "An account already uses that email or student ID.", null)
        } catch (_: SQLiteException) {
            result.error("account-storage", "Could not access accounts on this device. Try again.", null)
        } catch (_: GeneralSecurityException) {
            result.error("account-password", "Could not verify the password on this device.", null)
        } catch (_: IllegalArgumentException) {
            result.error("invalid-account", "Invalid account details.", null)
        }
    }

    private fun login(call: MethodCall): Map<String, String>? {
        val email = requireNotNull(call.argument<String>("email"))
        val password = requireNotNull(call.argument<String>("password"))
        return readableDatabase.rawQuery(
            "SELECT id, student_id, name, salt, password_hash FROM accounts WHERE email = ?",
            arrayOf(email),
        ).use { row ->
            if (!row.moveToFirst()) return@use null
            val hash = passwordHash(password, row.getBlob(3))
            if (!MessageDigest.isEqual(hash, row.getBlob(4))) return@use null
            user(row.getLong(0), row.getString(1), row.getString(2), email)
        }
    }

    private fun register(call: MethodCall): Map<String, String> {
        val email = requireNotNull(call.argument<String>("email"))
        val studentId = requireNotNull(call.argument<String>("studentId"))
        val name = requireNotNull(call.argument<String>("name"))
        val password = requireNotNull(call.argument<String>("password"))
        val salt = ByteArray(16).also(SecureRandom()::nextBytes)
        val values = ContentValues().apply {
            put("student_id", studentId)
            put("name", name)
            put("email", email)
            put("salt", salt)
            put("password_hash", passwordHash(password, salt))
        }
        val id = writableDatabase.insertOrThrow("accounts", null, values)
        return user(id, studentId, name, email)
    }

    private fun user(id: Long, studentId: String, name: String, email: String) = mapOf(
        "id" to "local-$id",
        "studentId" to studentId,
        "name" to name,
        "email" to email,
    )

    private fun passwordHash(password: String, salt: ByteArray): ByteArray {
        // This PBKDF2 variant is available across the APK's Android versions.
        val spec = PBEKeySpec(password.toCharArray(), salt, 1_300_000, 160)
        try {
            return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1").generateSecret(spec).encoded
        } finally {
            spec.clearPassword()
        }
    }
}
