import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["jobFunction", "employmentType", "bigSection", "salaryField", "percentageField", "skillsGroup", "averageRevenueField"]
  static values = {
    bigFunctions: Array,
    jobFunctionToSkillGroup: Object,
    averageRevenueFunctions: Array
  }

  connect() {
    this.toggleBigFields()
    this.toggleEmploymentFields()
    this.toggleSkillsGroup()
    this.toggleAverageRevenueField()
  }

  toggleBigFields() {
    const selected = this.jobFunctionTarget.value
    const show = this.bigFunctionsValue.includes(selected)
    this.bigSectionTarget.classList.toggle("hidden", !show)
  }

  toggleEmploymentFields() {
    const checked = this.employmentTypeTargets.filter(el => el.checked).map(el => el.value)
    this.salaryFieldTarget.classList.toggle("hidden", !checked.includes("employed"))
    this.percentageFieldTarget.classList.toggle(
      "hidden",
      !(checked.includes("self_employed") || checked.includes("percentage_based"))
    )
  }

  toggleAverageRevenueField() {
    console.log("toggleAverageRevenueField called")
    console.log("jobFunctionTarget:", this.jobFunctionTarget)
    console.log("averageRevenueFunctionsValue:", this.averageRevenueFunctionsValue)
    console.log("averageRevenueFieldTarget:", this.averageRevenueFieldTarget)
    const selected = this.jobFunctionTarget.value
    const show = this.averageRevenueFunctionsValue.includes(selected)
    this.averageRevenueFieldTarget.classList.toggle("hidden", !show)
  }

  toggleSkillsGroup() {
    const selectedFunction = this.jobFunctionTarget.value
    const activeGroup = this.jobFunctionToSkillGroupValue[selectedFunction]

    this.skillsGroupTargets.forEach(el => {
      const isMatch = el.dataset.functionGroup === activeGroup
      el.classList.toggle("hidden", !isMatch)
    })
  }
}
