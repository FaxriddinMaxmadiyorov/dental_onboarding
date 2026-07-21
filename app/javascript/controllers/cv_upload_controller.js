// app/javascript/controllers/cv_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropzone", "submitButton"]

  connect() {
    this.dropzoneTarget.addEventListener("click", () => this.inputTarget.click())

    this.dropzoneTarget.addEventListener("dragenter", this.preventAndHighlight.bind(this))
    this.dropzoneTarget.addEventListener("dragover", this.preventAndHighlight.bind(this))
    this.dropzoneTarget.addEventListener("dragleave", this.removeHighlight.bind(this))
    this.dropzoneTarget.addEventListener("drop", this.handleDrop.bind(this))
  }

  preventAndHighlight(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropzoneTarget.classList.add("border-teal-600", "bg-teal-50")
  }

  removeHighlight(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-teal-600", "bg-teal-50")
  }

  handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.removeHighlight(event)

    const files = event.dataTransfer.files
    if (files.length) {
      this.inputTarget.files = files
      this.submit()
    }
  }

  fileSelected() {
    if (this.inputTarget.files.length) this.submit()
  }

  submit() {
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Yuklanmoqda..."
    this.element.requestSubmit()
  }
}