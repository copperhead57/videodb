{*
  Edit template
  $Id: edit.tpl,v 1.8 2013/03/14 17:17:27 andig2 Exp $
*}

<!-- {$smarty.template} -->

<script type="text/javascript" src="{$template}js/edit.js"></script>

<!--
<div id="images">Alternative images:</div>
-->

<form action="edit.php" method="post" enctype="multipart/form-data" name="edi">
    <input type="hidden" name="id" value="{if !empty($video.id)}{$video.id}{/if}" />
    <input type="hidden" name="save" value="1" />

	<input type="hidden" name="autoid" value="{$autoid}" />
	<input type="hidden" name="oldmediatype" value="{$video.mediatype}" />

	<div class="row header">
		<div class="small-12 large-7 columns">
			<dl class="sub-nav" input-radio>
			<dt>{$lang.radio_look_caption}:</dt>
				{foreach $lookup key=k item=v}
				<dd {if $lookup_id==$k}class="active"{/if}><a href="lookup" value="{$k}">{$v}</a></dd>
				{/foreach}
			</dl>
		</div><!-- col -->

		<div class="small-12 large-5 columns">
			<div class="row collapse">
				<div class="small-6 large-6 columns">
					<dl class="sub-nav" input-checkbox>
					<dt>{$lang.create_}</dt>
						<dd {if !empty($add_flag)}class="active"{/if}><a href="add_flag" value="1">{$lang.add_another}</a></dd>
					</dl>
				</div><!-- col -->

				<div class="small-6 large-6 columns">
					<ul class="button-group right hide-for-small">
						<li>
							<a href="{if !empty($video.id)}show.php?id={$video.id}{else}index.php{/if}" class="button small">{$lang.cancel}</a>
							<a href="#" class="button small submit">{$lang.save}</a>
						</li>
					</ul>
					<ul class="button-group right hide-for-medium-up">
						<li>
							<a href="{if !empty($video.id)}show.php?id={$video.id}{else}index.php{/if}" class="button tiny">{$lang.cancel}</a>
							<a href="#" class="button tiny submit">{$lang.save}</a>
						</li>
					</ul>
				</div>
			</div><!-- row -->
		</div><!-- col -->
	</div><!-- button-bar -->


	<div class="row">
		<div class="small-12 large-10 columns large-centered">

			{if $http_error}
			<div class="alert-box alert">
				{$http_error}
				<a href="#" class="close">&times;</a>
			</div>
			{/if}


			<h4 class="subheader">{$lang.main_details}</h4>

			<div class="row">
				<div class="small-12 large-6 columns">
					<label for="title">{$lang.title} <a href="javascript:void(lookupData(document.edi.title.value))"><i class="foundicon-search inline"></i></a></label>
					<input type="text" name="title" id="title" value="{if !empty($video.q_title)}{$video.q_title}{/if}" class="autofocus" />
				</div><!-- col -->

				<div class="small-12 large-6 columns">
					<label for="subtitle">{$lang.subtitle} <a href="javascript:void(lookupData(document.edi.subtitle.value))"><i class="foundicon-search inline"></i></a></label>
					<input type="text" name="subtitle" id="subtitle" value="{if !empty($video.q_subtitle)}{$video.q_subtitle}{/if}"/>
				</div><!-- col -->
			</div><!-- row -->

			<div class="row">
				<div class="small-6 large-3 columns">
					<label for="director">{$lang.director}</label>
					<input type="text" name="director" id="director" value="{if !empty($video.q_director)}{$video.q_director}{/if}"/>
				</div><!-- col -->

				<div class="small-2 large-1 columns">
					<label for="year">{$lang.year}</label>
					<input type="text" name="year" id="year" alue="{if !empty($video.year)}{$video.year}{/if}"/>
				</div><!-- col -->

				<div class="small-4 large-2 columns">
					<div class="row collapse">
						<label for="runtime">{$lang.runtime}</label>
						<div class="small-8 columns">
							<input type="text" name="runtime" id="runtime" value="{if !empty($video.q_runtime)}{$video.q_runtime}{/if}" />
						</div><!-- col -->
						<div class="small-4 columns"><span class="postfix">min</span></div>
					</div><!-- row -->
				</div><!-- col -->

				<div class="small-6 large-3 columns">
					<label for="country">{$lang.country}</label>
					<input type="text" name="country" id="country" value="{if !empty($video.q_country)}{$video.q_country}{/if}"/>
				</div><!-- col -->

				<div class="small-6 large-3 columns">
					<label for="language">{$lang.language}</label>
					{$video.f_language}
				</div><!-- col -->
			</div><!-- row -->

			<div class="row">
				<div class="small-2 large-1 columns">
					<dl class="sub-nav" input-radio>
						<dt>{$lang.rating}</dt>
					</dl>
				</div><!-- col -->
				<div class="small-4 large-5 columns">
					<dl class="sub-nav tight" input-radio>
                                            {if !empty($video.rating)}
                                                {$rate = $video.rating}
                                            {else}
                                                {$rate = 0}
                                            {/if}
                                            {for $r=0 to 10}
                                                <dd {if $r == $rate|round}class="active"{/if}><a href="rating" value="{$r}">{$r}</a></dd>
                                            {/for}
					</dl>
				</div><!-- col -->

				<div class="small-6 columns">
					<dl class="sub-nav inline" input-checkbox>
						<dd {if !empty($video.seen)}class="active"{/if}><a href="seen" value="1">{$lang.seen}</a></dd>
					</dl>

					<dl class="sub-nav inline" input-checkbox>
						<dd {if !empty($video.istv)}class="active"{/if}><a href="istv" value="1">{$lang.tvepisode}</a></dd>
					</dl>

					<dl class="sub-nav inline" input-checkbox>
					{*	<dd {if $video.3d}class="active"{/if}><a href="3d" value="1">{$lang.3d}3D</a></dd> *}
                                                <dd {if !empty($video.3d)}class="active"{/if}>
                                                    <a href="3d" value="1">{$lang.3d}</a>
					</dl>
				</div><!-- col -->
			</div><!-- row -->

			<div class="row">
				<div class="small-2 large-1 columns">
					<dl class="sub-nav" input-checkbox>
						<dt>{$lang.genre}</dt>
					</dl>
				</div><!-- col -->
				<div class="small-10 large-11 columns">
					<dl class="sub-nav" input-checkbox>
						{foreach $genres as $genre}
						<dd {if !empty($genre.checked)}class="active"{/if}><a href="genres[]" value="{$genre.id}">{$genre.name}</a></dd>
						{/foreach}
					</dl>
				</div><!-- col -->
			</div><!-- row -->


			<h4 class="subheader">{$lang.media_details}</h4>

			<div class="row">
				<div class="small-12 large-6 columns">
				<div class="row">
					<div class="small-6 columns">
						<label for="mediatype">{$lang.mediatype}</label>
						{html_options name="mediatype" options=$mediatypes selected=$video.mediatype}
					</div><!-- col -->

					<div class="small-6 columns">
						<label for="diskid">{$lang.diskid}</label>
						<input type="text" name="diskid" id="diskid" value="{if !empty($video.q_diskid)}{$video.q_diskid}{/if}" />
					</div><!-- col -->
				</div></div><!-- row/col -->

				<div class="small-12 large-6 columns">
				<div class="row">
					{if !empty($owners)}
					<div class="small-6 columns">
						<label>{$lang.owner}</label>
						{html_options name=owner_id options=$owners selected=$video.owner_id}
					</div><!-- col -->
					{/if}

					<div class="{if !empty($owners)}small-6{else}small-12{/if} columns">
						<label for="imdbID">
							{$lang.extid}
						</label>

						<div class="row collapse">
							<div class="small-8 columns">
								<input type="text" name="imdbID" id="imdbID" value="{if !empty($video.q_imdbID)}{$video.q_imdbID}{/if}" />
							</div><!-- col -->
							<div class="small-4 columns">
								<a href="{if !empty($link)}{$link}{/if}" target="_blank" class="button postfix {if empty($link)}disabled{/if}">{$lang.visit}</a>
							</div><!-- col -->
						</div><!-- row -->
					</div><!-- col -->
				</div></div><!-- row/col -->
			</div><!-- row -->

			<div class="row">
				<div class="small-12 large-6 columns">
					<label for="imgurl">
						{$lang.coverurl}
						<a href="javascript:void(lookupImage(document.edi.title.value))"><i class="foundicon-search inline"></i></a>
					</label>

					<input type="text" name="imgurl" id="imgurl" value="{if !empty($video.q_imgurl)}{$video.q_imgurl}{/if}" />
				</div><!-- col -->

				<div class="small-12 large-6 columns">
					<label>{$lang.coverupload}</label>
					<div class="row collapse">
						<div class="small-10 columns">
							<input type="file" name="coverupload" id="coverupload" />
						</div><!-- col -->
						<div class="small-2 columns">
							<a href='#' class="button postfix input-browse">{$lang.input_browse}</a>
						</div><!-- col -->
					</div>
				</div><!-- col -->
			</div><!-- row -->


			<h4 class="subheader">{$lang.description_details}</h4>

			<div class="row">
				<div class="small-12 large-6 columns">
					<label for="plot">{$lang.plot}</label>
					<textarea class="large" name="plot" id="plot" wrap="virtual">{if !empty($video.q_plot)}{$video.q_plot}{/if}</textarea>
				</div><!-- col -->

				<div class="small-12 large-6 columns">
					<label for="actors">{$lang.cast}</label>
					<textarea class="large" name="actors" id="actors" wrap="off">{if !empty($video.q_actors)}{$video.q_actors}{/if}</textarea>
				</div><!-- col -->

				<div class="small-12 columns">
					<label for="comment">{$lang.comment}</label>
					<textarea class="large" name="comment" id="comment" wrap="virtual">{if !empty($video.q_comment)}{$video.q_comment}{/if}</textarea>
				</div><!-- col -->
			</div><!-- row -->


			<h4 class="subheader">{$lang.file_details}</h4>

			<div class="row">
				<div class="small-12 large-6 columns">
					<label for="filename">{$lang.filename}</label>
					<input type="text" name="filename" id="filename" value="{if !empty($video.q_filename)}{$video.q_filename}{/if}"/>
				</div><!-- col -->

				<div class="small-6 large-4 columns">
					<label for="filedate">{$lang.filedate}</label>
					<input type="text" name="filedate" id="filedate" value="{if !empty($video.q_filedate)}{$video.q_filedate}{/if}"/>
				</div><!-- col -->

				<div class="small-6 large-2 columns">
					<div class="row collapse">
						<label for="filesize">{$lang.filesize}</label>
						<div class="small-8 columns">
							<input type="text" name="filesize" id="filesize" value="{if !empty($video.q_filesize)}{$video.q_filesize}{/if}"/>
						</div><!-- col -->
						<div class="small-4 columns"><span class="postfix">{$lang.bytes}</span></div>
					</div><!-- row -->
				</div><!-- col -->
			</div><!-- row -->

			<div class="row">
				<div class="small-6 large-5 columns">
					<label for="audio_codec">{$lang.audiocodec}</label>
					<input type="text" name="audio_codec" id="audio_codec" value="{if !empty($video.q_audio_codec)}{$video.q_audio_codec}{/if}" />
				</div><!-- col -->

				<div class="small-6 large-5 columns">
					<label for="video_codec">{$lang.videocodec}</label>
					<input type="text" name="video_codec" id="video_codec" value="{if !empty($video.q_video_codec)}{$video.q_video_codec}{/if}" />
				</div><!-- col -->

				<div class="small-12 large-2 columns">
					<div class="row collapse">
						<label for="video_width">{$lang.dimension}</label>
						<div class="small-5 columns">
							<input type="text" name="video_width" id="video_width" value="{if !empty($video.q_video_width)}{$video.q_video_width}{/if}"/>
						</div><!-- col -->
						<div class="small-2 column"><span class="postfix">x</span></div>
						<div class="small-5 columns">
							<input type="text" name="video_height" id="video_height" value="{if !empty($video.q_video_height)}{$video.q_video_height}{/if}"/>
						</div><!-- col -->
					</div><!-- row -->
				</div><!-- col -->

			</div><!-- row -->


			{if !empty($video.custom1name) || !empty($video.custom2name) || !empty($video.custom3name) || !empty($video.custom4name)}
                            <h4 class="subheader">{$lang.custom_details}</h4>

                            <div class="row">
                                {if !empty($video.custom1name)}
                                    <div class="small-6 columns">
                                        <label>{$video.custom1name}</label>{$video.custom1in}
                                    </div><!-- col -->
                                {/if}

                                {if !empty($video.custom2name)}
                                    <div class="small-6 columns">
                                        <label>{$video.custom2name}</label>{$video.custom2in}
                                    </div><!-- col -->
                                {/if}
                            </div><!-- row -->

                            <div class="row">
                                {if !empty($video.custom3name)}
                                    <div class="small-6 columns">
                                        <label>{$video.custom3name}</label>{$video.custom3in}
                                    </div><!-- col -->
                                {/if}

                                {if !empty($video.custom4name)}
                                    <div class="small-6 columns">
                                        <label>{$video.custom4name}</label>{$video.custom4in}
                                    </div><!-- col -->
                                {/if}
                            </div><!-- row -->
			{/if}

		</div><!-- col -->
	</div><!-- row -->
</form>
