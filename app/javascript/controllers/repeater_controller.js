import { Controller } from "@hotwired/stimulus"

// Education / WorkExperience repeaterlari uchun umumiy controller.
// Ulash: <div data-controller="repeater" data-repeater-wrapper-selector-value=".nested-fields">
export default class extends Controller {
  static targets = ["template", "list"]

  add(event) {
    event.preventDefault()
    const uniqueId = new Date().getTime()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueId)
    this.listTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest(".nested-fields")
    const destroyInput = wrapper.querySelector("input[name*='_destroy']")

    if (destroyInput) {
      // mavjud (saqlangan) record — belgilab yashiramiz
      destroyInput.value = "1"
      wrapper.classList.add("hidden")
    } else {
      // hali saqlanmagan record — DOM'dan olib tashlaymiz
      wrapper.remove()
    }
  }
}
