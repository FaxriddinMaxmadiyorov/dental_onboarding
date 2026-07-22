import { application } from "./application"
import ConditionalFieldsController from "./conditional_fields_controller"
import RepeaterController from "./repeater_controller"
import CvUploadController from "./cv_upload_controller"

application.register("conditional-fields", ConditionalFieldsController)
application.register("repeater", RepeaterController)
application.register("cv-upload", CvUploadController)
application.register("redirect", RedirectController)
