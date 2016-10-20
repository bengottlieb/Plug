//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
let formatter = DateFormatter()

formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"


let string = formatter.string(from: Date())

let date = formatter.date(from: string)

