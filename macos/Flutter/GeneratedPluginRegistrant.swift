//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import cloud_firestore
import file_selector_macos
<<<<<<< HEAD
import firebase_core
=======
import firebase_auth
import firebase_core
import firebase_database
import firebase_storage
>>>>>>> 4fc7468ef6bca616ea4c63a5891a595141351667
import flutter_image_compress_macos
import geolocator_apple
import path_provider_foundation
import sqflite_darwin

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FLTFirebaseFirestorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseFirestorePlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
<<<<<<< HEAD
  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))
=======
  FLTFirebaseAuthPlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseAuthPlugin"))
  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))
  FLTFirebaseDatabasePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseDatabasePlugin"))
  FLTFirebaseStoragePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseStoragePlugin"))
>>>>>>> 4fc7468ef6bca616ea4c63a5891a595141351667
  FlutterImageCompressMacosPlugin.register(with: registry.registrar(forPlugin: "FlutterImageCompressMacosPlugin"))
  GeolocatorPlugin.register(with: registry.registrar(forPlugin: "GeolocatorPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
}
