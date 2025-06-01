let currentPumpData;
let selectedFuelType;
let fuelTypeWarnSent;

// Fuel Consumption Chart Dialog
let fuelChart, speedChart, consumptionChart;
let toggleChartFocusShortcut;
let chartTimestampsIndex = 1;
let chartTimestamps = [ 15, 30, 60, 90, 120, 150, 180 ];
let isRecording;

window.addEventListener("message", async function(event) {
    const item = event.data;
    if (item.data) {
        currentPumpData = item.data;
    }
    if (item.resourceName) {
        Utils.setResourceName(item.resourceName);
    }
    if (item.utils) {
        await Utils.loadLanguageModules(item.utils);
        Utils.post("setNuiVariablesLoaded", null, "setNuiVariablesLoaded");
    }
    if (item.type === "copyToClipboard") {
        const el = document.createElement("textarea");
        el.value = item.text;
        document.body.appendChild(el);
        el.select();
        document.execCommand("copy");
        document.body.removeChild(el);
    }
    if (item.openMainUI) {
        if (currentPumpData.isElectric) {
            $("#electric-time-to-recharge").html(`${Utils.translate("electricInterface.chargerAmount.timeToRechargeText")} <span id="electric-time-to-recharge-value"></span>`);

            $("#electric-charger-type-title").text(Utils.translate("electricInterface.chargerType.title"));
            $("#electric-charger-type-fast").text(Utils.translate("electricInterface.chargerType.fast.title"));
            $("#electric-charger-type-normal").text(Utils.translate("electricInterface.chargerType.normal.title"));
            $("#electric-charger-type-label-item-fast-price").text(Utils.translate("electricInterface.chargerType.pricePerKWh").format(Utils.currencyFormat(currentPumpData.pricePerLiter.electricfast)));
            $("#electric-charger-type-label-item-normal-price").text(Utils.translate("electricInterface.chargerType.pricePerKWh").format(Utils.currencyFormat(currentPumpData.pricePerLiter.electricnormal)));
            $("#electric-charger-type-label-item-fast-power").text(Utils.translate("electricInterface.chargerType.fast.power"));
            $("#electric-charger-type-label-item-normal-power").text(Utils.translate("electricInterface.chargerType.normal.power"));
            $("#electric-charger-continue-type-button").text(Utils.translate("electricInterface.continueButton"));

            $("#electric-charger-amount-title").text(Utils.translate("electricInterface.chargerAmount.title"));
            $("#electric-charger-amount-input").attr("placeholder", Utils.translate("electricInterface.chargerAmount.placeholder"));
            $("#electric-charger-continue-amount-button").text(Utils.translate("electricInterface.continueButton"));

            $("#electric-charger-payment-title").text(Utils.translate("electricInterface.chargerPayment.title"));
            $("#electric-charger-payment-bank").text(Utils.translate("electricInterface.chargerPayment.bank"));
            $("#electric-charger-payment-money").text(Utils.translate("electricInterface.chargerPayment.money"));

            if (currentPumpData.stationStock.electricfast == 0) {
                $("#electric-charger-fast-label-wrapper")
                    .attr("data-tooltip", Utils.translate("electricInterface.outOfStock"))
                    .attr("data-tooltip-location", "top");
                $("#charger-type-fast").prop("disabled", true);
            } else {
                $("#electric-charger-fast-label-wrapper")
                    .removeAttr("data-tooltip")
                    .removeAttr("data-tooltip-location");
                $("#charger-type-fast").prop("disabled", false);
            }

            if (currentPumpData.stationStock.electricnormal == 0) {
                $("#electric-charger-normal-label-wrapper")
                    .attr("data-tooltip", Utils.translate("electricInterface.outOfStock"))
                    .attr("data-tooltip-location", "top");
                $("#charger-type-normal").prop("disabled", true);
            } else {
                $("#electric-charger-normal-label-wrapper")
                    .removeAttr("data-tooltip")
                    .removeAttr("data-tooltip-location");
                $("#charger-type-normal").prop("disabled", false);
            }

            $(".electric-charger-type-container").css("display", "");
            $(".electric-charger-amount-container").css("display", "none");
            $(".electric-charger-payment-container").css("display", "none");
            $("#electric-charger-container").fadeIn(200);
        } else {
            if (currentPumpData.pumpModel == "prop_gas_pump_1a" || currentPumpData.pumpModel == "prop_gas_pump_1b" || currentPumpData.pumpModel == "prop_gas_pump_1c" || currentPumpData.pumpModel == "prop_gas_pump_1d") {
                $("#gas-pump-container-image").attr("src", `images/${currentPumpData.pumpModel}.png`);
            } else {
                $("#gas-pump-container-image").attr("src", `images/prop_gas_pump_1b.png`);
            }
            fuelTypeWarnSent = false;
            changeSelectedFuelType(currentPumpData.currentFuelType);
            $(".vehicle-fuel").text(Utils.translate("pumpInterface.vehicleFuel").format(`${Utils.numberFormat(currentPumpData.vehicleFuel, 1)} / ${Utils.numberFormat(currentPumpData.vehicleTankSize, 0)}`));
            $(".vehicle-fuel").attr("data-tooltip", Utils.translate("pumpInterface.vehicleFuelTooltip"));
            $(".bank-balance").text(Utils.currencyFormat(currentPumpData.bankBalance, 2));
            $(".cash-balance").text(Utils.currencyFormat(currentPumpData.cashBalance, 2));

            $(".fuel-type-button.regular").text(Utils.translate("pumpInterface.fuelTypes.regular"));
            $(".fuel-type-button.plus").text(Utils.translate("pumpInterface.fuelTypes.plus"));
            $(".fuel-type-button.premium").text(Utils.translate("pumpInterface.fuelTypes.premium"));
            $(".fuel-type-button.diesel").text(Utils.translate("pumpInterface.fuelTypes.diesel"));
            $(".confirm-button").text(Utils.translate("pumpInterface.confirm"));

            $("#confirm-refuel-payment-modal-title").text(Utils.translate("confirmRefuelModal.title"));
            $("#confirm-refuel-payment-modal-pay-bank").text(Utils.translate("confirmRefuelModal.paymentBank"));
            $("#confirm-refuel-payment-modal-pay-cash").text(Utils.translate("confirmRefuelModal.paymentCash"));

            $("#confirm-jerry-can-payment-modal-title").text(Utils.translate("confirmBuyJerryCanModal.title"));
            $("#confirm-jerry-can-payment-modal-desc").text(Utils.currencyFormat(currentPumpData.jerryCan.price, 2));
            $("#confirm-jerry-can-payment-modal-pay-bank").text(Utils.translate("confirmBuyJerryCanModal.paymentBank"));
            $("#confirm-jerry-can-payment-modal-pay-cash").text(Utils.translate("confirmBuyJerryCanModal.paymentCash"));

            $("#confirm-fuel-type-modal-title").text(Utils.translate("confirmFuelChangeModal.title"));
            $("#confirm-fuel-type-modal-desc").text(Utils.translate("confirmFuelChangeModal.description"));
            $("#confirm-fuel-type-modal-confirm").text(Utils.translate("confirmation_modal_confirm_button"));
            $("#confirm-fuel-type-modal-cancel").text(Utils.translate("confirmation_modal_cancel_button"));

            if (!currentPumpData.jerryCan.enabled) {
                $(".gas-pump-interactive-button").css("display", "none");
            }

            updateFuelAmountDisplay(true);

            $("#gas-pump-container").fadeIn(200);
        }
    }
    if (item.hideMainUI) {
        $("#gas-pump-container").fadeOut(200);
        $("#electric-charger-container").fadeOut(200);
    }
    if (item.showRefuelDisplay) {
        if (item.isElectric) {
            let percentageOfTankFilled = (item.currentDisplayFuelAmount / item.currentVehicleTankSize) * 100;
            $("#recharge-display-title").text(Utils.translate("rechargerDisplay.title"));
            $("#recharge-display-battery-level-span").text(`${Utils.numberFormat(percentageOfTankFilled, 0)}%`);
            $("#recharge-display-battery-liquid").css("width", `${percentageOfTankFilled}%`);
            $("#recharge-display-remaining-time-title").text(Utils.translate("rechargerDisplay.remainingTimeText"));
            updateRechargeDisplay((item.currentVehicleTankSize - item.currentDisplayFuelAmount), item.fuelTypePurchased);
            $("#recharge-display").fadeIn(200);
        } else {
            $("#refuel-display-pump-value").text(Utils.numberFormat(item.remainingFuelAmount, 2));
            $("#refuel-display-car-value").text(`${Utils.numberFormat(item.currentDisplayFuelAmount, 2)}/${Utils.numberFormat(item.currentVehicleTankSize, 2)}`);
            $(".refuel-display-liters").text(Utils.translate("pumpRefuelDisplay.liters"));
            $("#refuel-display-car-label").text(Utils.translate("pumpRefuelDisplay.carTank"));
            $("#refuel-display-pump-label").text(Utils.translate("pumpRefuelDisplay.remaining"));
            $("#refuel-display").fadeIn(200);
        }
    }
    if (item.hideRefuelDisplay) {
        $("#refuel-display").fadeOut(200);
        $("#recharge-display").fadeOut(200);
    }
    if (item.showFuelConsumptionChart) {
        toggleChartFocusShortcut = item.focusShortcut;
        isRecording = item.isRecording;

        createFuelConsumptionChartObject();
        openFuelConsumptionChart();
        setFuelConsumptionChartPosition(item.position);
        updateFuelConsumptionChart({ fuel: null, speed: null, consumption: null });
    }
    if (item.updateFuelConsumptionChart) {
        updateFuelConsumptionChart(item.fuelConsumptionData);
    }
    if (item.hideFuelConsumptionChart) {
        updateFuelConsumptionChart({ fuel: null, speed: null, consumption: null });
        $("#chart-dialog").fadeOut();
        // fuelChart.destroy();
        // speedChart.destroy();
        // consumptionChart.destroy();
    }
});

function updateRechargeDisplay(remainingFuelAmount, chargerType) {
    if (chargerType == "electricfast") chargerType = "fast";
    if (chargerType == "electricnormal") chargerType = "normal";
    if (chargerType && (chargerType === "fast" || chargerType === "normal")) {
        // Calculate the time to recharge based on remaining fuel amount and charger type's time per unit
        let timeToRecharge = remainingFuelAmount * currentPumpData.electric.chargeTypes[chargerType].time;

        // Convert time to minutes and seconds
        let timeToRechargeMinutes = Math.floor(timeToRecharge / 60);
        let timeToRechargeSeconds = timeToRecharge % 60;

        // Update the display with calculated time
        $("#recharge-display-remaining-time-value").text(Utils.translate("rechargerDisplay.remainingTimeValue").format(Utils.numberFormat(timeToRechargeMinutes, 0), Utils.numberFormat(timeToRechargeSeconds, 0)));
    } else {
        console.log("Invalid charger type or no charger type selected");
    }
}

/*=================
	FUNCTIONS
=================*/

function changeSelectedFuelType(fuelType) {
    if (fuelType == "regular" || fuelType == "plus" || fuelType == "premium" || fuelType == "diesel") {
        $(".fuel-type-button").removeClass("selected");
        $(`.fuel-type-button.${fuelType}`).addClass("selected");

        $(".price-per-liter").text(Utils.currencyFormat(currentPumpData.pricePerLiter[fuelType], 2));
        $(".station-stock").text(Utils.translate("pumpInterface.stationStock").format(Utils.numberFormat(currentPumpData.stationStock[fuelType])));
        selectedFuelType = fuelType;
    } else {
        console.log("Invalid fuel type chosen: " + fuelType);
    }
}

// Show the modal when confirmRefuel is called
function confirmRefuel() {
    if (fuelTypeWarnSent == false && currentPumpData.currentFuelType != selectedFuelType && currentPumpData.vehicleFuel > 0) {
        fuelTypeWarnSent = true;
        $("#confirm-fuel-type-modal").fadeIn();
    } else {
        let $input = $("#input-fuel-amount");
        let fuelAmount = parseInt($input.val());
        $("#confirm-refuel-payment-modal-desc").text(Utils.translate("confirmRefuelModal.description").format(fuelAmount, Utils.translate("pumpInterface.fuelTypes."+selectedFuelType), Utils.currencyFormat(fuelAmount * currentPumpData.pricePerLiter[selectedFuelType])));
        $("#confirm-refuel-payment-modal").fadeIn();
    }
}

// Empty vehicle's tank after user confirm fuel type change
function changeVehicleFuelType() {
    closeModal();
    Utils.post("changeVehicleFuelType", { selectedFuelType });
    currentPumpData.vehicleFuel = 0;
    $(".vehicle-fuel").text(Utils.translate("pumpInterface.vehicleFuel").format(Utils.numberFormat(currentPumpData.vehicleFuel, 2)));
}

// Confirm the buy jerry can action
function openBuyJerryCanModal() {
    closeModal();
    $("#confirm-jerry-can-payment-modal").fadeIn();
}

// Hide the modal
function closeModal() {
    $(".modal").fadeOut();
}

function confirmRefuelPayment(paymentMethod) {
    let $input = $("#input-fuel-amount");
    let fuelAmount = parseInt($input.val());
    Utils.post("confirmRefuel", { selectedFuelType, fuelAmount, paymentMethod });
    closeModal();
}

function confirmJerryCanPayment(paymentMethod) {
    Utils.post("confirmJerryCanPurchase", { paymentMethod });
    closeModal();
}

function increaseZoom() {
    // Get the current zoom level
    let currentZoom = parseFloat($("#gas-pump-container").css("zoom")) || 1;

    // Increase zoom by 5%
    let newZoom = currentZoom + 0.05;

    // Limit the zoom to a maximum of 1.4 (140%)
    if (newZoom > 1.4) {
        newZoom = 1.4;
    }

    // Apply the new zoom level
    $("#gas-pump-container").css("zoom", newZoom);
}

function decreaseZoom() {
    // Get the current zoom level
    let currentZoom = parseFloat($("#gas-pump-container").css("zoom")) || 1;

    // Decrease zoom by 5%
    let newZoom = currentZoom - 0.05;

    // Limit the zoom to a minimum of 0.8 (80%)
    if (newZoom < 0.8) {
        newZoom = 0.8;
    }

    // Apply the new zoom level
    $("#gas-pump-container").css("zoom", newZoom);
}

// Function to update the display with the 'L' suffix
function updateFuelAmountDisplay(setToMax = false) {
    let $input = $("#input-fuel-amount");
    let value = parseInt($input.val());

    // Set value to 1 if it's not a positive number
    if (isNaN(value) || value <= 0) {
        value = 1;
    }

    // Don't let it purchase more L than the vehicle can hold in the tank
    if (setToMax || (!isNaN(value) && value > currentPumpData.vehicleTankSize - currentPumpData.vehicleFuel)) {
        value = Math.floor(currentPumpData.vehicleTankSize - currentPumpData.vehicleFuel);
    }

    $input.val(value + " L");
}

// Pagination for electric chargers
function chargerTypeContinue() {
    let chargerType = getSelectedChargerType();
    if (chargerType && (chargerType == "fast" || chargerType == "normal")) {
        $("#electric-charger-amount-input").val(Math.floor(currentPumpData.vehicleTankSize - currentPumpData.vehicleFuel));
        calculateTimeToRecharge();
        $("#electric-charger-amount-type-selected").text(Utils.translate("electricInterface.chargerAmount.typeSelected").format(Utils.translate(`electricInterface.chargerType.${chargerType}.title`)));
        $(".electric-charger-type-container").css("display", "none");
        $(".electric-charger-amount-container").css("display", "");
    }
}

function chargerAmountContinue() {
    let $input = $("#electric-charger-amount-input");
    let currentValue = parseInt($input.val()) || 0;
    let newWidthPercentage = ((currentPumpData.vehicleFuel / currentPumpData.vehicleTankSize) * 100) + ((currentValue / currentPumpData.vehicleTankSize) * 100);

    if (currentValue <= 0 || newWidthPercentage > 100) {
        return;
    }

    let chargerType = getSelectedChargerType();
    $("#electric-charger-pay-button").text(Utils.translate("electricInterface.chargerPayment.payButton").format(Utils.currencyFormat(currentValue * currentPumpData.pricePerLiter["electric"+chargerType], 2)));
    $(".electric-charger-amount-container").css("display", "none");
    $(".electric-charger-payment-container").css("display", "");
}

function chargerAmountReturn() {
    $(".electric-charger-type-container").css("display", "");
    $(".electric-charger-amount-container").css("display", "none");
    $(".electric-charger-payment-container").css("display", "none");
}

function confirmRecharge() {
    let $input = $("#electric-charger-amount-input");
    let fuelAmount = parseInt($input.val()) || 0;
    Utils.post("confirmRefuel", { selectedFuelType: "electric" + getSelectedChargerType(), fuelAmount, paymentMethod: getSelectedElectricPaymentMethod() });
}

function chargerPaymentReturn() {
    $(".electric-charger-type-container").css("display", "none");
    $(".electric-charger-amount-container").css("display", "");
    $(".electric-charger-payment-container").css("display", "none");
}

function getSelectedChargerType() {
    const selectedInput = $("input[name='charger-type']:checked");
    return selectedInput.length && !selectedInput.prop("disabled") ? selectedInput.val() : null;
}

function getSelectedElectricPaymentMethod() {
    const selectedInput = $("input[name='charger-payment']:checked");
    return selectedInput.length ? selectedInput.val() : null;
}

function calculateTimeToRecharge() {
    let $input = $("#electric-charger-amount-input");
    let currentValue = parseInt($input.val());

    // Allow empty input temporarily; validate only non-empty values
    if ($input.val().trim() === "" || isNaN(currentValue) || currentValue <= 0) {
        currentValue = 0;
    }

    if (currentValue > 1000) {
        currentValue = 1000;
        $input.val(currentValue);
    }

    let chargerType = getSelectedChargerType();
    if (chargerType && (chargerType == "fast" || chargerType == "normal")) {
        let timeToRecharge = currentValue * currentPumpData.electric.chargeTypes[chargerType].time;

        // Calculate minutes and seconds
        let timeToRechargeMinutes = Math.floor(timeToRecharge / 60);
        let timeToRechargeSeconds = timeToRecharge % 60;

        $("#electric-time-to-recharge-value").text(Utils.translate("electricInterface.chargerAmount.timeToRechargeValue").format(Utils.numberFormat(timeToRechargeMinutes, 0), Utils.numberFormat(timeToRechargeSeconds, 0)));

        let newWidthPercentage = ((currentPumpData.vehicleFuel / currentPumpData.vehicleTankSize) * 100) + ((currentValue / currentPumpData.vehicleTankSize) * 100);
        $("#electric-amount-progress-bar").css("width", newWidthPercentage + "%");

        if (newWidthPercentage > 100) {
            $("#electric-amount-progress-bar").css("background", "red");
        } else {
            $("#electric-amount-progress-bar").css("background", "");
        }
    } else {
        console.log("No charger type selected");
    }
}

/*===================
	CHART DIALOG
===================*/

function openFuelConsumptionChart() {
    const $dialog = $("#chart-dialog");

    $("#chart-dialog-title").text(Utils.translate("fuelConsumptionChart.title"));
    $("#chart-dialog-footer-text").text(Utils.translate("fuelConsumptionChart.footer.focus"));
    $("#stepper-chart-recording-input").text(Utils.translate("fuelConsumptionChart.footer.recordsLength").format(chartTimestamps[chartTimestampsIndex]));
    $("#start-stop-recording-label").text(Utils.translate("fuelConsumptionChart.footer.toggleRecording"));
    $("#start-stop-recording").prop("checked", isRecording);

    $dialog.css({
        right: "",
        bottom: "",
        display: "flex",
    }).fadeIn();

    $dialog.draggable({
        handle: ".dialog-header",
    }).resizable({
        minHeight: 450,
        minWidth: 300,
        maxHeight: $(window).height()*0.8,
        maxWidth: $(window).width()*0.8,
    });
    speedChart.resize();
    consumptionChart.resize();
    fuelChart.resize();
}

function setFuelConsumptionChartPosition(position) {
    const $dialog = $("#chart-dialog");
    const windowWidth = $(window).width();
    const dialogWidth = $dialog.outerWidth();

    let top = 10;
    let left;

    // Horizontal position
    if (position === "left") {
        left = 10;
    } else {
        left = windowWidth - dialogWidth - 10;
    }

    $dialog.css({
        top: `${top}px`,
        left: `${left}px`,
    });
}


function updateFuelConsumptionChart(latestData) {
    const now = Date.now();

    if (fuelChart && speedChart && consumptionChart) {
        fuelChart.data.datasets[0].data.push({ x: now, y: latestData.fuel });
        speedChart.data.datasets[0].data.push({ x: now, y: latestData.speed });
        consumptionChart.data.datasets[0].data.push({ x: now, y: latestData.consumption });
    }
    fuelChart.update("quiet");
    speedChart.update("quiet");
    consumptionChart.update("quiet");
}

function createFuelConsumptionChartObject() {
    if (fuelChart || speedChart || consumptionChart) { return; }

    Chart.defaults.color = "rgba(218, 218, 218, 0.73)";
    Chart.overrides.line.spanGaps = false;

    const baseOptions = {
        responsive: true,
        maintainAspectRatio: false,
        elements: { point: { radius: 0 } },
        animation: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
            legend: {
                position: "bottom",
                labels: { boxWidth: 3, boxHeight: 3 },
            },
            streaming: {
                frameRate: 10,
            },
        },
        scales: {
            x: {
                type: "realtime",
                realtime: {
                    duration: 30000,
                    refresh: 1000,
                    delay: 1000,
                },
            },
            y: {
                beginAtZero: true,
            },
        },
    };

    // Fuel Chart

    fuelChart = new Chart(document.getElementById("fuel-chart"), {
        type: "line",
        data: {
            datasets: [{
                label: Utils.translate("fuelConsumptionChart.chartLabels.fuel"),
                data: [],
                borderColor: "#FFD800",
                cubicInterpolationMode: "monotone",
            }],
        },
        options: {
            ...baseOptions,
            scales: {
                ...baseOptions.scales,
                y: {
                    ...baseOptions.scales.y,
                    suggestedMax: 100,
                    title: { display: true, text: Utils.translate("fuelConsumptionChart.chartLabels.fuel") },
                },
            },
        },
    });

    // Speed Chart

    speedChart = new Chart(document.getElementById("speed-chart"), {
        type: "line",
        data: {
            datasets: [{
                label: Utils.translate("fuelConsumptionChart.chartLabels.speed"),
                data: [],
                borderColor: "#0026FF",
                cubicInterpolationMode: "monotone",
            }],
        },
        options: {
            ...baseOptions,
            scales: {
                ...baseOptions.scales,
                y: {
                    ...baseOptions.scales.y,
                    suggestedMax: 140,
                    title: { display: true, text: Utils.translate("fuelConsumptionChart.chartLabels.speed") },
                },
            },
        },
    });

    // Consumption Chart

    consumptionChart = new Chart(document.getElementById("consumption-chart"), {
        type: "line",
        data: {
            datasets: [{
                label: Utils.translate("fuelConsumptionChart.chartLabels.consumption"),
                data: [],
                borderColor: "#7F0000",
                cubicInterpolationMode: "monotone",
            }],
        },
        options: {
            ...baseOptions,
            scales: {
                ...baseOptions.scales,
                y: {
                    ...baseOptions.scales.y,
                    suggestedMax: 0.3,
                    title: { display: true, text: Utils.translate("fuelConsumptionChart.chartLabels.consumption") },
                },
            },
        },
    });
}


/*=================
	LISTENERS
=================*/

$(window).click(function(event) {
    // Close the modal when clicking outside of it
    if ($(event.target).is(".modal")) {
        closeModal();
    }
});

$(document).on("keydown", function(event) {
    // Handle press of Esc key
    if (event.key === "Escape" || event.keyCode === 27) {
        // Check if the modal is open by checking if it's visible
        if ($("#chart-dialog").is(":visible")) {
            closeFuelConsumptionChartUI();
        } else if ($(".modal").is(":visible")) {
            closeModal();
        } else {
            closeUI();
        }
    }
    if (event.key === toggleChartFocusShortcut
        || event.key === "w" || event.key === "W"
        || event.key === "a" || event.key === "A"
        || event.key === "d" || event.key === "D"
        || event.key === "s" || event.key === "S") {
        // Check if the modal is open by checking if it's visible
        if ($("#chart-dialog").is(":visible")) {
            removeFocusFuelConsumptionChartUI();
        }
    }
});

$(document).ready(function() {
    // Handle the add button
    $(".refuel-add").click(function() {
        let $input = $("#input-fuel-amount");
        let currentValue = parseInt($input.val()) || 0;
        if (currentValue < Math.floor(currentPumpData.vehicleTankSize - currentPumpData.vehicleFuel)) {
            $input.val((currentValue + 1) + " L");
        }
    });
    $(".recharge-add").click(function() {
        let $input = $("#electric-charger-amount-input");
        let currentValue = parseInt($input.val()) || 0;
        if (currentValue < Math.floor(currentPumpData.vehicleTankSize - currentPumpData.vehicleFuel)) {
            $input.val((currentValue + 1));
            calculateTimeToRecharge();
        }
    });

    // Handle the sub button
    $(".refuel-sub").click(function() {
        let $input = $("#input-fuel-amount");
        let currentValue = parseInt($input.val()) || 0;
        if (currentValue > 1) {
            $input.val((currentValue - 1) + " L");
        }
    });
    $(".recharge-sub").click(function() {
        let $input = $("#electric-charger-amount-input");
        let currentValue = parseInt($input.val()) || 0;
        if (currentValue > 1) {
            $input.val((currentValue - 1));
            calculateTimeToRecharge();
        }
    });

    // Remove 'L' suffix on focus to allow numeric input, and add it back on blur
    $("#input-fuel-amount").on("focus", function() {
        $(this).val(parseInt($(this).val()) || 1);
    }).on("blur", function() {
        updateFuelAmountDisplay();
    });

    // Recalculate time when change input
    $("#electric-charger-amount-input").on("input", function() {
        calculateTimeToRecharge();
    });
    $("#electric-charger-amount-input").on("blur", function() {
        let $input = $(this);
        let currentValue = parseInt($input.val());

        // If invalid, reset to 0
        if (isNaN(currentValue) || currentValue <= 0) {
            $input.val(0);
        }
    });

    // Handle chart buttons
    $("#start-stop-recording").change(function() {
        if ($(this).is(":checked")) {
            startRecordingGraph();
        } else {
            stopRecordingGraph();
        }
    });

    $("#increase-chart-recording").click(function() {
        if (chartTimestampsIndex < chartTimestamps.length - 1) {
            chartTimestampsIndex++;
            $("#stepper-chart-recording-input").text(Utils.translate("fuelConsumptionChart.footer.recordsLength").format(chartTimestamps[chartTimestampsIndex]));
            changeRecordingIndexGraph();
        }
    });

    $("#decrease-chart-recording").click(function() {
        if (chartTimestampsIndex > 0) {
            chartTimestampsIndex--;
            $("#stepper-chart-recording-input").text(Utils.translate("fuelConsumptionChart.footer.recordsLength").format(chartTimestamps[chartTimestampsIndex]));
            changeRecordingIndexGraph();
        }
    });
});


/*=================
	CALLBACKS
=================*/

function closeUI(){
    Utils.post("close","");
}

function stopRecordingGraph(){
    fuelChart.options.scales.x.realtime.pause = true;
    speedChart.options.scales.x.realtime.pause = true;
    consumptionChart.options.scales.x.realtime.pause = true;
    Utils.post("stopRecordingGraph","");
}

function startRecordingGraph(){
    fuelChart.options.scales.x.realtime.pause = false;
    speedChart.options.scales.x.realtime.pause = false;
    consumptionChart.options.scales.x.realtime.pause = false;
    Utils.post("startRecordingGraph","");
}

function changeRecordingIndexGraph(){
    fuelChart.options.scales.x.realtime.duration = chartTimestamps[chartTimestampsIndex] * 1000;
    speedChart.options.scales.x.realtime.duration = chartTimestamps[chartTimestampsIndex] * 1000;
    consumptionChart.options.scales.x.realtime.duration = chartTimestamps[chartTimestampsIndex] * 1000;
    Utils.post("changeRecordingIndexGraph",chartTimestampsIndex);
}

function closeFuelConsumptionChartUI(){
    Utils.post("closeFuelConsumptionChartUI","");
}

function removeFocusFuelConsumptionChartUI(){
    Utils.post("removeFocusFuelConsumptionChartUI","");
}