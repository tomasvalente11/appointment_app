import { application } from "./application"
import AppointmentModalController from "./appointment_modal_controller"
import NutritionistSelectorController from "./nutritionist_selector_controller"
import RadiusToggleController from "./radius_toggle_controller"
import TabsController from "./tabs_controller"

application.register("appointment-modal", AppointmentModalController)
application.register("nutritionist-selector", NutritionistSelectorController)
application.register("radius-toggle", RadiusToggleController)
application.register("tabs", TabsController)
