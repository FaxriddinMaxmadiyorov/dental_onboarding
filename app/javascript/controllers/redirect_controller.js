// app/javascript/controllers/redirect_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    window.history.replaceState({}, "", this.urlValue)
    Turbo.visit(this.urlValue, { action: "replace" })
  }
}