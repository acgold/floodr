#' Visualize impacts on structures from bathtub inundation modeling
#'
#' @param model_output A 'bathtub' model output item
#' @param model A 'bathtub' model item
#' @param elev The DEM used in modeling inundation created by 'setup_DEM'
#' @param type_column Column in model item that indicates the type of structures. Default is NULL
#' @param filter_value Type of structure (as string) to select from 'type_column'. Multiple values should be put in vector (i.e., using c() ). Default is NULL
#' @param type Static "plot" or "interactive_map"
#' @param hide_labels Hide labels of column values? T or F, default is F
#' @param simplify_labels Simplify labels of column values? T or F, default is T
#' @param label_size Size of labels, default is 2
#' @param xmin Set the minimum value of the x axis
#' @param xmax Set the maximum value of x axis
#' @param filename Name of the plot. Will be stored in the 'bathtub_output/figures/
#' @param workspace Path to bathtub output folder
#'
#' @return A \code{ggplot} plot (type = "plot") or \code{mapview} map (type = "interactive_map") of structures impacted during inundation modeling
#' @examples
#'bft_plot <- viz_structures(model_output = bft_model_output,
#'model = bft_model_1D,
#'elev = raster::raster(bft_elev),
#'type_column = "Code",
#'filter_value = c("D_I", "C_B"),
#'type = "plot",
#'hide_labels = T,
#'simplify_labels = T,
#'label_size = 2,
#'filename = "bft_structures_impact_plot.png",
#'workspace = workspace,
#'panel.grid = element_blank())

viz_structures <- function(model_output,
                           model,
                           elev,
                           type_column = NULL,
                           filter_value = NULL,
                           type = "plot",
                           hide_labels = F,
                           simplify_labels = T,
                           label_size = 2,
                           xmin = -3,
                           xmax = 4,
                           filename = NULL,
                           workspace,
                           ...){
  theme_params <- list(...)

  total_impacted_pipes <- model_output$pipes
  total_impacted_nodes <- model_output$nodes
  total_np_nodes <- model_output$np_nodes
  total_impacted_structures <- model_output$structures
  total_np_structures <- model_output$np_structures
  total_flooding <- model_output$flooding
  overlay <- NULL

  if(!is.null(model_output$overlay)){
    overlay <- model_output$overlay
  }

  if(is.null(filter_value) | is.null(type_column)){
    n_struc = nrow(model$structures %>% dplyr::filter(structureID %in% unique(model$nodes %>% dplyr::pull(structureID))))

  }

  if(!is.null(filter_value) & !is.null(type_column)){
    n_struc = nrow(model$structures %>% dplyr::filter(!!sym(type_column) %in% filter_value) %>% dplyr::filter(structureID %in% unique(model$nodes %>% dplyr::pull(structureID))))
    total_impacted_structures <- total_impacted_structures %>% dplyr::filter(!!sym(type_column) %in% filter_value) %>% dplyr::filter(structureID %in% unique(model_output$nodes %>% dplyr::pull(structureID)))
    total_np_structures <- total_np_structures %>% dplyr::filter(!!sym(type_column) %in% filter_value) %>% dplyr::filter(structureID %in% unique(model_output$nodes %>% dplyr::pull(structureID)))

  }

  if(type == "plot" & is.null(overlay)){
    plot_data <- total_impacted_structures %>%
      dplyr::mutate(binned_perc = factor(forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T)),
                                         levels = c("Low confidence",
                                                    "(Missing)",
                                                    "[0,20]",
                                                    "(20,40]",
                                                    "(40,60]",
                                                    "(60,80]",
                                                    "(80,99]",
                                                    "(99,100]")),
                    confidence_class = factor(confidence_class, levels = c("Low","High"))) %>%
      dplyr::group_by(water_elevation, binned_perc, confidence_class) %>%
      dplyr::summarise(n_perc = n()/n_struc) %>%
      dplyr::filter(!is.na(water_elevation)) %>%
      dplyr::ungroup()

    plot_data$binned_perc[plot_data$confidence_class == "Low"] <- "Low confidence"

    agg_data <- total_impacted_structures %>%
      dplyr::mutate(binned_perc = factor(forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T)),
                                         levels = c("(Missing)",
                                                    "[0,20]",
                                                    "(20,40]",
                                                    "(40,60]",
                                                    "(60,80]",
                                                    "(80,99]",
                                                    "(99,100]"))) %>%
      dplyr::group_by(water_elevation) %>%
      dplyr::summarise(n_perc = n()/n_struc) %>%
      dplyr::filter(!is.na(water_elevation)) %>%
      dplyr::ungroup()

    confidence_plot_data <- total_impacted_structures %>%
      dplyr::mutate(confidence_class = factor(confidence_class, levels = c("Low","High"))) %>%
      dplyr::mutate(binned_perc = factor(forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T)),
                                         levels = c("(Missing)",
                                                    "[0,20]",
                                                    "(20,40]",
                                                    "(40,60]",
                                                    "(60,80]",
                                                    "(80,99]",
                                                    "(99,100]")),
                    confidence_class = factor(confidence_class, levels = c("Low","High"))) %>%
      dplyr::group_by(water_elevation, binned_perc, confidence_class) %>%
      dplyr::summarise(n_perc = n()/n_struc) %>%
      dplyr::filter(!is.na(water_elevation)) %>%
      dplyr::ungroup()

    cols <- c("[0,20]" = "#440154FF",
              "(20,40]" = "#414487FF",
              "(40,60]" = "#2A788EFF",
              "(60,80]" = "#22A884FF",
              "(80,99]" = "#7AD151FF",
              "(99,100]" = "#FDE725FF",
              "(Missing)" = "black",
              "Low confidence" = "dark grey")

    label_data <- total_impacted_structures %>%
      dplyr::group_by(water_elevation) %>%
      dplyr::summarise(n_perc = n()/n_struc) %>%
      dplyr::filter(!is.na(water_elevation)) %>%
      dplyr::group_by(water_elevation) %>%
      dplyr::mutate(label = ifelse(sum(hide_labels) == 0, round((n_perc * 100), digits = 1), "")) %>%
      dplyr::group_by(label) %>%
      dplyr::mutate(min_of_label = (water_elevation == min(water_elevation))) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(label = ifelse(min_of_label==F & simplify_labels == T, "", label))

    impacted_struc_total <- ggplot2::ggplot(data = plot_data %>% units::drop_units())+
      geom_col(aes(x=water_elevation, y = n_perc*100, fill = binned_perc), position = "stack")+
      ggrepel::geom_text_repel(data = label_data %>% units::drop_units(),
                      aes(x = water_elevation, y = n_perc * 100, label = label),
                      vjust = -.5, size = label_size, color = "grey20", direction = "y", box.padding = 0)+
      geom_line(data = total_np_structures %>%
                  dplyr::mutate(binned_perc =  forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
                  dplyr::group_by(water_elevation) %>%
                  dplyr::summarise(n_perc = n()/n_struc) %>%
                  dplyr::filter(!is.na(water_elevation)) %>%
                  units::drop_units(), aes(x=water_elevation, y = n_perc*100,color = "No Pipes"))+
      geom_point(data = total_np_structures %>%
                   dplyr::mutate(binned_perc =  forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
                   dplyr::group_by(water_elevation) %>%
                   dplyr::summarise(n_perc = n()/n_struc) %>%
                   dplyr::filter(!is.na(water_elevation)) %>%
                   units::drop_units(), aes(x=water_elevation, y = n_perc*100,color = "No Pipes"))+
      scale_fill_manual(values = cols)+
      scale_x_continuous(breaks= scales::pretty_breaks(), limits = c(xmin, xmax))+
      scale_y_continuous(breaks= scales::pretty_breaks(), limits = c(NA, max(agg_data$n_perc)*103))+
      scale_color_manual(values = c("black"), name = "",labels = "No Pipes")+
      scale_alpha_manual(values = c(0.4,1))+
      # scale_color_manual(values = c("black","grey","black"), name = "",labels = "No Pipes")+
      ylab("Impacted inlets (% of total)")+
      xlab(paste0("MHHW (",units(total_impacted_structures$s_inv_elev)$numerator,")"))+
      theme_bw()+
      theme(legend.background = element_blank(),
            legend.key = element_blank(),
            text = element_text(family = "Times New Roman"))+
      guides(fill = F)+
      theme(legend.position = "none")+
      theme(...)


    impacted_struc_ratio <- plot_data %>%
      ungroup() %>%
      units::drop_units() %>%
      ggplot()+
      geom_col(aes(x=water_elevation, y = n_perc*100, fill = binned_perc), position = "fill")+
      coord_cartesian(ylim=c(0,1))+
      geom_line(aes(water_elevation, y = -100, color = "No Pipes"))+
      geom_point(aes(water_elevation, y = -100, color = "No Pipes"))+
      scale_fill_manual(values = cols,name = "Volume filled (%)", limits = names(cols), labels = c("0 - 20", "20 - 40","40 - 60","60 - 80","80 - 99","100+", "Unknown", "Low Confidence"))+
      scale_x_continuous(breaks= scales::pretty_breaks(), limits = c(xmin, xmax))+
      scale_y_continuous(breaks= scales::pretty_breaks(), labels = scales::label_percent())+
      ylab("Relative amount")+
      scale_color_manual(values = c("black"), name = element_blank())+
      xlab(paste0("MHHW (",units(total_impacted_structures$s_inv_elev)$numerator,")"))+
      theme_bw()+
      theme(text = element_text(family = "Times New Roman"),
            legend.key.size = unit(5,"mm"),
            legend.margin=margin(-0.5,0,0,0, unit="cm"),
            legend.title = element_text(size = 12))+
      theme(...)

    # confidence_low <- ggplot2::ggplot(data = confidence_plot_data %>% units::drop_units() %>%
    #                                     filter(confidence_class == "Low"))+
    #   geom_col(aes(x=water_elevation, y = n_perc*100, fill = binned_perc), position = "stack")+
    #   # ggrepel::geom_text_repel(data = label_data %>% units::drop_units(),
    #   #                          aes(x = water_elevation, y = n_perc * 100, label = label),
    #   #                          vjust = -.5, size = label_size, color = "grey20", direction = "y", box.padding = 0)+
    #   geom_line(data = total_np_structures %>%
    #               dplyr::mutate(binned_perc =  forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
    #               dplyr::group_by(water_elevation) %>%
    #               dplyr::summarise(n_perc = n()/n_struc) %>%
    #               dplyr::filter(!is.na(water_elevation)) %>%
    #               units::drop_units(), aes(x=water_elevation, y = n_perc*100,color = "No Pipes"))+
    #   geom_point(data = total_np_structures %>%
    #                dplyr::mutate(binned_perc =  forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
    #                dplyr::group_by(water_elevation) %>%
    #                dplyr::summarise(n_perc = n()/n_struc) %>%
    #                dplyr::filter(!is.na(water_elevation)) %>%
    #                units::drop_units(), aes(x=water_elevation, y = n_perc*100,color = "No Pipes"))+
    #   scale_fill_manual(values = cols)+
    #   scale_x_continuous(breaks= scales::pretty_breaks())+
    #   scale_y_continuous(breaks= scales::pretty_breaks(), limits = c(NA, max(agg_data$n_perc)*103))+
    #   scale_color_manual(values = c("black"), name = "",labels = "No Pipes")+
    #   ylab(" ")+
    #   xlab(paste0("MHHW (",units(total_impacted_structures$s_inv_elev)$numerator,")"))+
    #   theme_bw()+
    #   theme(legend.background = element_blank(),
    #         legend.key = element_blank(),
    #         text = element_text(family = "Times New Roman"),
    #         legend.position = "none")+
    #   guides(fill=F)+
    #   ggtitle("Low confidence")+
    #   theme(...)

    # confidence_high <- ggplot2::ggplot(data = confidence_plot_data %>% units::drop_units() %>%
    #                                     filter(confidence_class == "High"))+
    #   geom_col(aes(x=water_elevation, y = n_perc*100, fill = binned_perc), position = "stack")+
    #   # ggrepel::geom_text_repel(data = label_data %>% units::drop_units(),
    #   #                          aes(x = water_elevation, y = n_perc * 100, label = label),
    #   #                          vjust = -.5, size = label_size, color = "grey20", direction = "y", box.padding = 0)+
    # geom_line(data = total_np_structures %>%
    #             dplyr::mutate(binned_perc =  forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
    #             dplyr::group_by(water_elevation) %>%
    #             dplyr::summarise(n_perc = n()/n_struc) %>%
    #             dplyr::filter(!is.na(water_elevation)) %>%
    #             units::drop_units(), aes(x=water_elevation, y = n_perc*100,color = "No Pipes"))+
    # geom_point(data = total_np_structures %>%
    #              dplyr::mutate(binned_perc =  forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
    #              dplyr::group_by(water_elevation) %>%
    #              dplyr::summarise(n_perc = n()/n_struc) %>%
    #              dplyr::filter(!is.na(water_elevation)) %>%
    #              units::drop_units(), aes(x=water_elevation, y = n_perc*100,color = "No Pipes"))+
    # scale_fill_manual(values = cols)+
    #   scale_x_continuous(breaks= scales::pretty_breaks())+
    #   scale_y_continuous(breaks= scales::pretty_breaks(), limits = c(NA, max(agg_data$n_perc)*103))+
    #   scale_color_manual(values = c("black"), name = "",labels = "No Pipes")+
    #   ylab(" ")+
    #   xlab(paste0("MHHW (",units(total_impacted_structures$s_inv_elev)$numerator,")"))+
    #   theme_bw()+
    #   theme(legend.background = element_blank(),
    #         legend.key = element_blank(),
    #         text = element_text(family = "Times New Roman"),
    #         legend.position = "none")+
    #   guides(fill=F)+
    #   ggtitle("High confidence")
    #   theme(...)

    # confidence <- confidence_low / confidence_high

    impact_plot <- impacted_struc_total + impacted_struc_ratio

    if(!is.null(filename)){
      ggplot2::ggsave(filename = filename, plot = impact_plot, path = paste0(workspace,"/figures/"),
             width = 180, height = 70, units = "mm")
    }

    return(impact_plot)
  }

  if(type == "plot" & !is.null(overlay)){
    plot_data <- total_impacted_structures %>%
      dplyr::mutate(binned_perc = forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
      dplyr::group_by(water_elevation, binned_perc) %>%
      dplyr::summarise(n_perc = n()/n_struc) %>%
      dplyr::filter(!is.na(water_elevation)) %>%
      dplyr::ungroup()

    agg_data <- total_impacted_structures %>%
      dplyr::mutate(binned_perc = forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
      dplyr::group_by(water_elevation) %>%
      dplyr::summarise(n_perc = n()/n_struc) %>%
      dplyr::filter(!is.na(water_elevation)) %>%
      dplyr::ungroup()

    cols <- c("[0,20]" = "#440154FF",
              "(20,40]" = "#414487FF",
              "(40,60]" = "#2A788EFF",
              "(60,80]" = "#22A884FF",
              "(80,99]" = "#7AD151FF",
              "(99,100]" = "#FDE725FF",
              "(Missing)" = "dark grey")

    label_data <- total_impacted_structures %>%
      dplyr::group_by(water_elevation) %>%
      dplyr::summarise(n_perc = n()/n_struc) %>%
      dplyr::filter(!is.na(water_elevation)) %>%
      dplyr::group_by(water_elevation) %>%
      dplyr::mutate(label = ifelse(sum(hide_labels) == 0, round((n_perc * 100), digits = 1), "")) %>%
      dplyr::group_by(label) %>%
      dplyr::mutate(min_of_label = water_elevation == min(water_elevation)) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(label = ifelse(min_of_label==F & simplify_labels == T, "", label))

    impacted_struc_total <- ggplot2::ggplot(data = plot_data)+
      geom_col(aes(x=factor(1), y = n_perc*100, fill = binned_perc), position = "stack", width = 0.4)+
      ggrepel::geom_text_repel(data = label_data,
                      aes(x = factor(1), y = n_perc * 100, label = label),
                      vjust = -.5, size = label_size, color = "grey20", direction = "y", box.padding = 0)+

      scale_fill_manual(values = cols)+
      scale_y_continuous(breaks= scales::pretty_breaks(), limits = c(NA, 100))+
      scale_color_manual(values = c("black"), name = "",labels = "No Pipes")+
      ylab("Impacted inlets (% of total)")+
      xlab(names(overlay))+
      theme_bw()+
      theme(legend.background = element_blank(),
            legend.key = element_blank())+
      guides(fill = F)+
      theme(legend.position = c(.3,.9),
            axis.title.x = element_text(size = 12),
            axis.text.x = element_blank(),
            panel.grid.major.x = element_blank())

    if(nrow(total_np_structures)>0){
      impacted_struc_total <- impacted_struc_total +
        geom_line(data = total_np_structures %>%
                    dplyr::mutate(binned_perc =  forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
                    dplyr::group_by(water_elevation) %>%
                    dplyr::summarise(n_perc = n()/n_struc) %>%
                    dplyr::filter(!is.na(water_elevation)), aes(x=factor(1), y = n_perc*100,color = "No Pipes"))+
        geom_point(data = total_np_structures %>%
                     dplyr::mutate(binned_perc =  forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
                     dplyr::group_by(water_elevation) %>%
                     dplyr::summarise(n_perc = n()/n_struc) %>%
                     dplyr::filter(!is.na(water_elevation)), aes(x=factor(1), y = n_perc*100,color = "No Pipes"))
    }

    impacted_struc_ratio <- total_impacted_structures %>%
      dplyr::mutate(binned_perc = forcats::fct_explicit_na(cut(structure_perc_fill , breaks = c(0,20,40,60,80,99,100), include.lowest = T, right = T))) %>%
      dplyr::group_by(water_elevation, binned_perc) %>%
      dplyr::summarise(n_perc = n()/n_struc) %>%
      dplyr::filter(!is.na(water_elevation)) %>%
      dplyr::ungroup() %>%
      ggplot()+
      geom_col(aes(x=factor(1), y = n_perc*100, fill = binned_perc), position = "fill", width = 0.4)+
      coord_cartesian(ylim=c(0,1))+
      scale_fill_manual(values = cols,name = "Structure \nvolume \nfilled (%)", limits = names(cols), labels = c("0 - 20", "20 - 40","40 - 60","60 - 80","80 - 99","100", "Unknown"))+
      # scale_x_continuous(breaks= pretty_breaks())+
      scale_y_continuous(breaks= scales::pretty_breaks(), labels = scales::label_percent())+
      ylab("Relative amount")+
      xlab(names(overlay))+
      theme_bw()+
      theme(axis.title.x = element_text(size = 12),
            axis.text.x = element_blank(),
            panel.grid.major.x = element_blank())

    if(class(overlay)[1] == "RasterLayer"){
      static_map <- ggplot2::ggplot()+
        theme_minimal()+
        geom_sf(data = raster::rasterToContour(elev, nlevels = 5) %>% sf::st_as_sf() %>% dplyr::mutate(level = as.numeric(as.character(level))),aes(color = level))+
        geom_sf(data = model$pipes, size = 1)+
        geom_sf(data = overlay %>%
                  stars::st_as_stars() %>%
                  sf::st_as_sf(as_points = FALSE,
                           merge = TRUE,
                           connect8 = T), fill = "royal blue", color = NA, alpha = 0.8)+
        geom_sf(data = total_impacted_pipes, color = "red", size = 1)+
        geom_sf(data = total_impacted_structures, color = "red", size = 2)+
        scale_color_distiller(palette = "Greys", name = "Elevation (ft, MHHW)")
    }


    impact_plot <- cowplot::plot_grid(impacted_struc_total, impacted_struc_ratio, static_map, rel_widths = c(1,1,3))

    if(!is.null(filename)){
      ggplot2::ggsave(filename = filename, plot = impact_plot, path = paste0(workspace,"/figures/"),
             width = 180, height = 70, units = "mm")
    }

    return(impact_plot)
  }

  if(type == "interactive_map"){
    min_wl <- min(units::drop_units(total_impacted_structures$water_elevation))
    max_wl <- max(units::drop_units(total_impacted_structures$water_elevation))
    structure_list <- sort(unique(total_impacted_structures$structureID))
    wl_seq <- sort(unique(total_impacted_structures$water_elevation))

    p <- foreach::foreach(i = sort(unique(total_impacted_structures$structureID))) %do% {
      d <- total_impacted_structures %>%
        dplyr::filter(structureID == i) %>%
        tibble::as_tibble() %>%
        units::drop_units()

      if(length(setdiff(wl_seq,d$water_elevation)) > 0){
        missing <- setdiff(wl_seq,d$water_elevation)

        added_rows <-d %>%
          dplyr::slice(rep(1, each = length(missing))) %>%
          dplyr::mutate(structure_fill_height = 0,
                 structure_perc_fill = 0,
                 structure_surcharge = 0,
                 water_elevation = missing)

        d <- added_rows %>%
          rbind(d)
      }

      disclaimer <- dplyr::if_else(is.na(sum(d$s_inv_elev)) | sum(d$s_inv_elev == d$s_elev) > 0 , "Warning", "")
      disclaimer_sub <- dplyr::if_else(is.na(sum(d$s_inv_elev))| sum(d$s_inv_elev == d$s_elev) > 0, "Flooding calculated using surface elevation \nbecause invert elevation is missing \nor same as surface elevation", "")

      ggplot2::ggplot(data = d)+
        geom_line(aes(x = water_elevation, y = structure_perc_fill/100))+
        geom_point(aes(x = water_elevation, y = structure_perc_fill/100))+
        ggtitle(disclaimer, subtitle = disclaimer_sub)+
        theme_light()+
        xlab(paste0("Water elevation (",units(total_impacted_structures$s_inv_elev)$numerator,")"))+
        ylab("Structure fill percent")+
        scale_x_continuous(breaks = scales::pretty_breaks(),limits = c(min_wl, max_wl))+
        scale_y_continuous(breaks = scales::pretty_breaks(), limits = c(0,1), labels = scales::label_percent())
    }


    int_map <- mapview::mapview(x=model$pipes,color="black", layer.name = "Pipes")+
      mapview::mapview(model$structures %>%
                units::drop_units() %>%
                dplyr::mutate(issue_spots = (is.na(s_inv_elev) | s_inv_elev == s_elev)) %>%
                dplyr::filter(issue_spots == T),
              color = "red",
              layer.name = "Warnings",
              fill = F)+
      mapview::mapview(total_impacted_structures %>%
                units::drop_units() %>%
                dplyr::group_by(structureID) %>%
                dplyr::summarise(min_impact_height = min(water_elevation)) %>%
                  dplyr::ungroup(),
              zcol = "min_impact_height",
              layer.name = "Water level of first impact - Structures",
              popup = leafpop::popupGraph(p, type = "svg"),
              cex = 5)

    return(int_map)
  }
}

