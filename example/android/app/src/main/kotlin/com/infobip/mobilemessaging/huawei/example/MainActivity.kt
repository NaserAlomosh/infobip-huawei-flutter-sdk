package com.blink.cbt.huawei

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val id = resources.getIdentifier(
            "app_id",
            "string",
            packageName,
        )

        Log.d("HMS_TEST", "app_id resource id = $id")

        if (id != 0) {
            Log.d("HMS_TEST", "app_id value = ${getString(id)}")
        }
    }
}