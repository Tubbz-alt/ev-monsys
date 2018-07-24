from operator import attrgetter

from ryu.app import simple_switch_13
from ryu.controller import ofp_event
from ryu.controller.handler import MAIN_DISPATCHER, DEAD_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.app.wsgi import ControllerBase, WSGIApplication, route
from ryu.lib import hub
from ryu.lib import dpid as dpid_lib

import json
from webob import Response

simple_monitor_instance_name = 'simple_monitor_api_app'
url = '/simplemonitor/flowtable/{dpid}'

class SimpleMonitor13(simple_switch_13.SimpleSwitch13):

    _CONTEXTS = {'wsgi': WSGIApplication}

    def __init__(self, *args, **kwargs):
        super(SimpleMonitor13, self).__init__(*args, **kwargs)
        self.datapaths = {}
        wsgi = kwargs['wsgi']
        wsgi.register(SimpleMonitorController,
                      {simple_monitor_instance_name: self})
        self.monitor_thread = hub.spawn(self._monitor)

    @set_ev_cls(ofp_event.EventOFPStateChange,
                [MAIN_DISPATCHER, DEAD_DISPATCHER])
    def _state_change_handler(self, ev):
        datapath = ev.datapath
        if ev.state == MAIN_DISPATCHER:
            if datapath.id not in self.datapaths:
                self.logger.debug('register datapath: %016x', datapath.id)
                self.datapaths[datapath.id] = {'datapath': datapath}
        elif ev.state == DEAD_DISPATCHER:
            if datapath.id in self.datapaths:
                self.logger.debug('unregister datapath: %016x', datapath.id)
                del self.datapaths[datapath.id]

    def _monitor(self):
        self.logger.debug('start sending stats request')
        while True:
            for dp in self.datapaths.values():
                self._request_stats(dp['datapath'])
            hub.sleep(10)

    def _request_stats(self, datapath):
        self.logger.debug('send stats request: %016x', datapath.id)
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        req = parser.OFPFlowStatsRequest(datapath)
        datapath.send_msg(req)

    @set_ev_cls(ofp_event.EventOFPFlowStatsReply, MAIN_DISPATCHER)
    def _port_stats_reply_handler(self, ev):
        body = ev.msg.body
        dpid = ev.msg.datapath.id
        if dpid not in self.datapaths:
            return

        self.datapaths[dpid]['json'] = {}
        self.datapaths[dpid]['json']['dpid'] = dpid   
        self.datapaths[dpid]['json']['flow_table'] = ev.msg.to_jsondict()['OFPFlowStatsReply']['body']

class SimpleMonitorController(ControllerBase):

    def __init__(self, req, link, data, **config):
        super(SimpleMonitorController, self).__init__(req, link, data, **config)
        self.simple_monitor = data[simple_monitor_instance_name]

    def getAlldpid(self, datapaths):
        json_dpid = {}
        for dpid in datapaths:
            if 'json' not in datapaths[dpid]:
                return {'content': 'no flow table found'}
            json_dpid[dpid] = datapaths[dpid]['json']
        return json_dpid

    @route('simplemonitor', url, methods=['GET'],
           requirements={'dpid': dpid_lib.DPID_PATTERN})
    def list_flow_table(self, req, **kwargs):

        dpid = kwargs['dpid']
        
        if dpid == 0:
            body = json.dumps(self.getAlldpid(self.simple_monitor.datapaths))
            return Response(content_type='application/json', body=body)
        
        if dpid not in self.simple_monitor.datapaths:
            return Response(status=404)

        if 'json' not in self.simple_monitor.datapaths[dpid]:
            return Response(status=404)

        body = json.dumps(self.simple_monitor.datapaths[dpid]['json'])
        return Response(content_type='application/json', body=body)
