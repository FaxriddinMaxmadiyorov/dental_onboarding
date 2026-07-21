import { Controller } from "@hotwired/stimulus"

// Ulash: <form data-controller="conditional-fields">
export default class extends Controller {
  static targets = ["jobFunction", "employmentType", "bigSection", "salaryField", "percentageField"]

  static values = {
    bigFunctions: Array // ["general_dentist", "dental_hygienist", "specialist"]
  }

  connect() {
    this.toggleBigFields()
    this.toggleEmploymentFields()
  }

  toggleBigFields() {
    const selected = this.jobFunctionTarget.value
    const show = this.bigFunctionsValue.includes(selected)
    this.bigSectionTarget.classList.toggle("hidden", !show)
  }

  toggleEmploymentFields() {
    const checked = this.employmentTypeTargets
      .filter(el => el.checked)
      .map(el => el.value)

    this.salaryFieldTarget.classList.toggle("hidden", !checked.includes("employed"))
    this.percentageFieldTarget.classList.toggle(
      "hidden",
      !(checked.includes("self_employed") || checked.includes("percentage_based"))
    )
  }
}
