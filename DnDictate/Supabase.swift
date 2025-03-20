//
//  Supabase.swift
//  DnDictate
//
//  Created by Sam Robinson on 3/20/25.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://kwdtkmdppbizgrhiuair.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3ZHRrbWRwcGJpemdyaGl1YWlyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4MzYzMDAsImV4cCI6MjA1MzQxMjMwMH0.nbXalXiXDrOmaBMI1OlTw7gr74dZiLj93orCOqXD2qs"
)
