import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropzone", "submitButton"]

  connect() {
    this.dropzoneTarget.addEventListener("dragover", e => e.preventDefault())
    this.dropzoneTarget.addEventListener("drop", this.handleDrop.bind(this))
  }

  handleDrop(event) {
    event.preventDefault()
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
