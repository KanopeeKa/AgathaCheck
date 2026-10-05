/// Care add route with weigh-in routine family preselected (W9 / FW-20).
String weightMonitoringCareAddPath(String petId) =>
    '/pet/$petId/care/add?family=weight_monitoring';
