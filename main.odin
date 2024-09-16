package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:strconv"

buf_len :: proc(str: string, cat_str: string) -> int {
   return (len(str) + 1) * (len(cat_str) + 1)
}

distance :: proc(str: string, cat_str: string, buf: []u8) -> u8 #no_bounds_check {
   Array_2D :: struct {
      buf: []u8,
      width: int,
   }

   access :: proc(view: Array_2D, x: int, y: int) -> ^u8 {
      return &view.buf[x + y * view.width]
   }

   view := Array_2D{
      buf = buf,
      width = len(str) + 1,
   }

   for x in 0..=len(str) {
      access(view, x, 0)^ = 0
   }

   INF :: 128
   for y in 1..=len(cat_str) {
      access(view, 0, y)^ = INF
   }

   for x in 1..=len(str) {
      for y in 1..=len(cat_str) {
         result := min(access(view, x, y - 1)^ + 1, INF)
         if is_vowel(str[x - 1]) == is_vowel(cat_str[y - 1]) {
            result = min(result, access(view, x - 1, y - 1)^ + 1)
         }
         if str[x - 1] == cat_str[y - 1] {
            result = min(result, access(view, x - 1, y - 1)^)
         }
         access(view, x, y)^ = result
      }
   }
   y := len(cat_str)
   result := access(view, 0, y)^
   for x in 1..=len(str) {
      result = min(access(view, x, y)^, result)
   }

   return result
}

is_vowel :: proc(letter: u8) -> bool {
   letter := letter
   switch letter {
      case 'A'..='Z':
         letter -= 'A'
         letter += 'a'
   }
   switch letter {
      case 'a', 'e', 'i', 'o', 'u', 'y':
         return true
   }
   return false
}

main :: proc() {
   usage_message :: proc() {
      fmt.println("Usage: {} <WORD> <DISTANCE>", slice.get(os.args, 0) or_else "THIS_PROGRAMS_NAME")
   }
   if len(os.args) != 3 {
      usage_message()
      return
   }
   cat_str := os.args[1]
   dist, dist_ok := strconv.parse_int(os.args[2])
   if !dist_ok {
      usage_message()
      return
   }
   words: [dynamic]string
   defer delete(words)
   data_bytes, data_ok := os.read_entire_file("words.txt")
   if !data_ok {
      fmt.println("Couldn't open words.txt")
      return
   }
   defer delete(data_bytes)

   data_str := cast(string)data_bytes
   max_len := 0

   for line in strings.split_lines_iterator(&data_str) {
      append(&words, line)
      max_len = max(max_len, buf_len(line, cat_str))
   }

   buf := make([]u8, max_len)
   defer delete(buf)

   score_map: map[int][dynamic]string
   defer {
      for _, dyn_arr in score_map {
         delete(dyn_arr)
      }
      delete(score_map)
   }

   for word in words {
      d := int(distance(word, cat_str, buf))
      if d not_in score_map {
         score_map[d] = {}
      }
      append(&score_map[d], word)
   }

   for word in (score_map[dist] or_else {}) {
      fmt.println(word)
   }
}
