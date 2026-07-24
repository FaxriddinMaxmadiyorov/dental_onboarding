import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropzone", "submitButton", "placeholder", "fileInfo", "fileName", "fileSize", "consentCheckbox", "consentError"]

  connect() {
    this.dropzoneTarget.addEventListener("click", (e) => {
      if (e.target.closest("[data-action='cv-upload#clearFile']")) return
      this.inputTarget.click()
    })

    this.dropzoneTarget.addEventListener("dragenter", this.preventAndHighlight.bind(this))
    this.dropzoneTarget.addEventListener("dragover", this.preventAndHighlight.bind(this))
    this.dropzoneTarget.addEventListener("dragleave", this.removeHighlight.bind(this))
    this.dropzoneTarget.addEventListener("drop", this.handleDrop.bind(this))

    this.element.addEventListener("submit", this.handleSubmit.bind(this))
    this.consentCheckboxTarget.addEventListener("change", () => this.hideConsentError())
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
      this.showFileInfo(files[0])
    }
  }

  fileSelected() {
    if (this.inputTarget.files.length) {
      this.showFileInfo(this.inputTarget.files[0])
    }
  }

  showFileInfo(file) {
    this.placeholderTarget.classList.add("hidden")
    this.fileInfoTarget.classList.remove("hidden")

    this.fileNameTarget.textContent = file.name
    this.fileSizeTarget.textContent = this.formatSize(file.size)

    this.submitButtonTarget.disabled = false
  }

  clearFile(event) {
    event.stopPropagation()

    this.inputTarget.value = ""
    this.placeholderTarget.classList.remove("hidden")
    this.fileInfoTarget.classList.add("hidden")
    this.submitButtonTarget.disabled = true
  }

  formatSize(bytes) {
    if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(0)} KB`
    }
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  handleSubmit(event) {
    if (!this.consentCheckboxTarget.checked) {
      event.preventDefault()
      this.showConsentError()
      this.consentCheckboxTarget.focus()
      return
    }

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Yuklanmoqda..."
  }

  showConsentError() {
    this.consentErrorTarget.classList.remove("hidden")
    this.consentCheckboxTarget.classList.add("ring-2", "ring-red-500", "rounded")
  }

  hideConsentError() {
    this.consentErrorTarget.classList.add("hidden")
    this.consentCheckboxTarget.classList.remove("ring-2", "ring-red-500", "rounded")
  }

}