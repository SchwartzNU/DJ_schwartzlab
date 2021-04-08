function recreateSchema()

%%drop everything
safemode = dj.config('safemode');
dj.config('safemode', false);

sl_zach.Symphony().drop();
sl_zach.Cell().drop();
sl_zach.SymphonyEpochSettings().drop();
sl_zach.SymphonyProtocolSettings().drop();
sl_zach.SymphonyProjectorSettings().drop();

dj.config('safemode',safemode);


end